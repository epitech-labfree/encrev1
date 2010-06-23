package org.rtmpy.examples.simple.receiveVideo
{
  import flash.display.LoaderInfo;
  import flash.events.IOErrorEvent;
  import flash.events.NetStatusEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.TimerEvent;
  import flash.media.SoundTransform;
  import flash.media.Video;
  import flash.net.NetConnection;
  import flash.net.NetStream;
  import flash.net.Responder;
  import flash.utils.Timer;
  import flash.utils.clearInterval;
  import flash.utils.setInterval;

  import mx.controls.Alert;
  import mx.controls.Button;
  import mx.controls.sliderClasses.Slider;
  import mx.controls.sliderClasses.SliderDirection;
  import mx.core.Application;
  import mx.core.UIComponent;
  import mx.events.FlexEvent;
  import mx.events.SliderEvent;


  /**
   * @author Thijs Triemstra (info@collab.nl)
   */
  public class ReceiveVideo extends Application
  {
    private var videoURL		: String = "DidNotProvideStreamName";
    private var _rtmpURL		: String = "rtmp://localhost/encrev1";
    private var _encre_token		: String = "I_did_not_supplied_any_token_but_i_should_have";
    //private var videoURL		: String = this.application.parameters.stream;
    //private var _rtmpURL		: String = 'rtmp://'+Application.application.parameters.server+'/oflaDemo';
    private var connection		: NetConnection;
    private var stream			: NetStream;
    private var video			: Video;

    private var st:SoundTransform = new SoundTransform();
    public var volume:Slider;
/*		public var buffer:Slider;*/
    public var button_audio		: Button;
    public var button_video		: Button;
    public var button_playstop	: Button;
    public var button_pausestart: Button;
    public var receive_cb		: Boolean = true;
    public var receive_au		: Boolean = true;
    //public var box				: VBox;
    public var videoPanel       : UIComponent;
    public var position			: Slider;
    private var stream_name     : String;
    private var stream_live     : Boolean = true;

    public var connected    : Boolean = false;
    public var playback_active:Boolean = false;
    public var playback_paused:Boolean = false;
    private var si:Number = 0;
    private var no_scrub_count:int = 0;

    [Bindable]
      private var metaData:Object = {duration:0};

    public var scrubbing:Boolean = false;

    public function ReceiveVideo()
    {
      super();
      this.addEventListener(FlexEvent.APPLICATION_COMPLETE, onAppInit);
    }

    private function getparam(key:String, notfound:String=''): String
    {
      try
      {
        var keyStr:String;
        var valueStr:String;
        var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
        //   			var url:String = String(this.root.loaderInfo.url);
        //   			var loaderURL:String = String(this.root.loaderInfo.loaderURL);
        //   			trace(this.root['stream']);
        //   			trace(this.root['server']);
        for (keyStr in paramObj)
        {
          if (keyStr == key)
          {
            return String(paramObj[keyStr]);
          }
        }
      }
      catch (error:Error)
      {
        trace(error.toString());
        return '';
      }
      return notfound;
    }

    private function onAppInit(event:FlexEvent): void
    {
      //var videoPanel:UIComponent = new UIComponent();

      var height:int = int(getparam("height", "120"));
      var width:int = int(getparam("width", "160"));

      videoPanel.setActualSize(width, height);
      videoPanel.width = width;
      videoPanel.height = height;

      video = new Video(width, height);
      videoPanel.addChild(video);

      stream_name = getparam("stream");
      if (getparam("live"))
        stream_live = true;
      if (getparam("recorded"))
      {
        stream_live = false;
        button_playstop.visible = true;
        button_playstop.height = 16;
        button_pausestart.visible = true;
        button_pausestart.height = 16;
      }
      if (getparam("showposition"))
      {
        position.visible = true;
        position.width = width;
        position.height = 16;
        position.direction = SliderDirection.HORIZONTAL;
        position.minimum = 0;
        position.liveDragging = true;
        position.snapInterval = 1;
        /*position.tickInterval = 20;*/
        position.value = 0;
        position.addEventListener(SliderEvent.CHANGE, positionSliderChanged);
        stop_scrub();
        if (!si)
          si = setInterval(updateScrubBar, 100);
      }

      volume.direction = SliderDirection.VERTICAL;
      volume.minimum = 0;
      volume.maximum = 10;
      volume.liveDragging = true;
      volume.snapInterval = 1;
      volume.tickInterval = 2;
      volume.value = 10;
      volume.addEventListener(SliderEvent.CHANGE, sliderChanged);

      /* doesn't work properly, allowing buffer to change during playback

         buffer.direction = SliderDirection.VERTICAL;
         buffer.minimum = 0;
         buffer.maximum = 5;
         buffer.liveDragging = true;
         buffer.snapInterval = 1;
         buffer.tickInterval = 1;
         buffer.value = 0;
         buffer.validateNow();
         buffer.addEventListener(SliderEvent.CHANGE, sliderBufferChanged);
      */
      connect();
    }
    public function updateScrubBar():void
    {
      try
      {
        if (stream && !scrubbing)
        {
          if (no_scrub_count <= 0)
          {
            position.value = stream.time;
          }
          else
          {
            no_scrub_count = no_scrub_count - 1;
          }
        }
      }catch(e:Error)
      {
      }
    }

    private function sliderChanged(e:SliderEvent):void
    {
      var vol:Number = Number(e.target.value) / 10.0;
      st.volume = vol;
      trace(' Slider changed: ' + vol);
      if (stream != null)
      {
        stream.soundTransform = st;
      }
    }
    /* doesn't work properly, allowing buffer to change during playback
       private function sliderBufferChanged(e:SliderEvent):void {
       stream.bufferTime = e.target.value;
       trace(' Slider changed: ' + e.target.value);
       }
    */
    private function netStatusHandler(event:NetStatusEvent): void
    {
      trace('netStatusHandler: ' + event.info.code);

      switch (event.info.code)
      {
      case "NetStream.Play.Empty":
        stream.bufferTime = int(getparam("buffertime", "1"));
        break;
      case "NetStream.Play.Full":
        stream.bufferTime = int(getparam("buffertime", "1"));
        break;
      case "NetStream.Play.Start":
//		            stream.bufferTime = 0;
        break;
      case "NetConnection.Connect.Success":
        get_stream_name_and_connect();
        break;
      case "NetStream.Play.UnpublishNotify":
        trace("stream disconnected by publisher");
        check_retry_connect();
        break;
      case "NetConnection.Connect.Failed":
      case "NetConnection.Connect.Closed":
        check_retry_connect();
      break;
      case "NetStream.Play.StreamNotFound":
        trace("Stream not found: " + videoURL);
        check_retry_connect();
        break;
      }
    }

    private function check_retry_connect(): void
    {
      disconnectStream();
      if (receive_cb) /* reconnect automatically if desired */
      {
        var myTimer:Timer = new Timer(5000, 1); // 5 seconds
        myTimer.addEventListener(TimerEvent.TIMER, runOnce);
        myTimer.start();
      }
    }
    private function runOnce(event:TimerEvent):void {
      trace("runOnce() called");
      connect();
    }

    private function get_stream_name_and_connect():void
    {
      stream_name = getparam("stream", "");

      if (stream_name != "")
      {
        connectStream();
        return;
      }

      var user_name:String = getparam("user", "");

      if (user_name == "")
        return;

      var nc_responder:Responder = new Responder(get_stream_name_response_and_connect, null);
      // connection.call("demoService.getUserStreamName", nc_responder, user_name);
    }

    public function get_stream_name_response_and_connect (resp:String):void
    {
      trace("get_stream_name_response:" + resp);
      stream_name = resp;
      if (stream_name != "")
      {
        connectStream();
        return;
      }
    }

    public function enableVideo(): void
    {
      if (connection && connection.connected && stream)
      {
        if (receive_cb)
        {
          stream.bufferTime = int(getparam("buffertime", "1"));
          video.attachNetStream(stream);
        }
        else
        {
          video.attachNetStream(null);
        }
        stream.receiveVideo(receive_cb);
      }
      else if (receive_cb)
      {
        connect();
      }
      else
      {
        disconnectStream();
      }
    }

    public function enableAudio(): void
    {
      if (connection.connected)
      {
        stream.receiveAudio(receive_au);
      }
    }
    public function audio_toggle(): void
    {
      if (!receive_au)
      {
        button_audio.styleName = "buttonaudioon";
        button_audio.toolTip = "Mute";
        receive_au = true;
        enableAudio();
      }
      else
      {
        button_audio.styleName = "buttonaudiooff";
        button_audio.toolTip = "Audio On";
        receive_au = false;
        enableAudio();
      }
    }

    public function pausestart_toggle(): void
    {
      if (!playback_paused)
      {
        button_pausestart.styleName = "buttonstart";
        button_pausestart.toolTip = "Resume";
        playback_paused = true;
        stream.pause();
      }
      else
      {
        button_pausestart.styleName = "buttonpause";
        button_pausestart.toolTip = "Pause";
        playback_paused = false;
        stream.resume();
      }
    }

    public function playstop_toggle(): void
    {
      if (!playback_active)
      {
        button_playstop.styleName = "buttonstop";
        button_playstop.toolTip = "Stop";
        playback_active = true;
        button_pausestart.styleName = "buttonpause";
        button_pausestart.toolTip = "Pause";
        playback_paused = false;
        stream.play(stream_name);
      }
      else
      {
        button_playstop.styleName = "buttonplay";
        button_playstop.toolTip = "Play";
        playback_active = false;
        stream.close();
      }
    }
    public function video_toggle(): void
    {
      if (!receive_cb)
      {
        button_video.styleName = "buttonvideoon";
        button_video.toolTip = "Video Off";
        receive_cb = true;
        enableVideo();
      }
      else
      {
        button_video.styleName = "buttonvideooff";
        button_video.toolTip = "Video On";
        receive_cb = false;
        enableVideo();
      }
    }


    public function connect(): void
    {
      connection = new NetConnection();
      connection.client = this;
      connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
      connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
      connection.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);

      _rtmpURL = getparam('server');
      _encre_token = getparam('token', 'I_did_not_supplied_any_token_but_i_should_have');
      trace(String(_rtmpURL));
      trace(String(_encre_token));
      connection.connect(_rtmpURL, _encre_token);
      connected = true;
    }

    public function onBWDone(): void {}
    public function onPlayStatus(obj:Object): void {}

    private function connectStream(): void
    {
      trace(stream_name);

      if (connection == null) /* huh? what we doing here?? */
        return;

      stream = new NetStream(connection);
      stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
      stream.client = this;
      stream.bufferTime = int(getparam("buffertime", "1"));

      video.attachNetStream(stream);
      stream.play(stream_name);
      playback_active = true;
      playback_paused = false;
    }

    public function disconnectStream(): void
    {
      if (stream)
      {
        video.clear();
        video.attachNetStream(null);
        stream.receiveVideo(false);
        stream.receiveAudio(false);
        stream.close();
      }
      if (connection)
        connection.close();
      //delete connection;
      //delete stream;
      connection = null;
      stream = null;

      connected = false;
    }

    private function securityErrorHandler(event:SecurityErrorEvent): void
    {
      Alert.show(event.toString(), "securityErrorHandler");
    }

    private function ioErrorHandler(event:IOErrorEvent): void
    {
      Alert.show(event.toString(), "ioErrorHandler");
    }

    public function start_scrub():void
    {
      scrubbing = true;
/*        	if (si)
                clearInterval(si);
	        si = 0;*/
      if (stream)
        stream.pause();
    }
    public function stop_scrub():void
    {
      scrubbing = false;
      if (stream)
        stream.resume();
    }
    public function scrubVideo(event:Event):void
    {
      trace("scrub video" + position.value);
      no_scrub_count = 5;
      scrubbing = false;
      stream.pause();
      stream.seek(position.value);
      stream.resume();
    }

    private function positionSliderChanged(e:SliderEvent):void
    {
      if (stream && scrubbing)
      {
        no_scrub_count = 5;
        stream.pause();
        stream.seek(e.target.value);
        stream.resume();
      }
    }

    public function onMetaData(info:Object): void
    {
      metaData = info;
      position.maximum = metaData.duration;


/*	        Alert.show("metadata: duration=" + info.duration + " width=" +
                info.width + " height=" + info.height + " framerate=" +
                info.framerate, "onMetaData");*/
    }

    public function onCuePoint(info:Object): void
    {
/*	        Alert.show("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type, "onCuePoint");*/
    }

  }
}
