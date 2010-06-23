package org.rtmpy.examples.simple.vidPublish
{
  import com.renaun.samples.net.FMSConnection;
  import flash.media.SoundTransform;

  import flash.display.LoaderInfo;
  import flash.events.TimerEvent;
  import flash.events.ActivityEvent;
  import flash.events.NetStatusEvent;
  import flash.events.SecurityErrorEvent;
  import flash.media.Camera;
  import flash.media.Microphone;
  import flash.media.Video;
  import flash.net.NetConnection;
  import flash.net.NetStream;
  import flash.net.ObjectEncoding;
  import flash.net.Responder;
  import flash.utils.Timer;

  import mx.containers.HBox;
  import mx.controls.CheckBox;
  import mx.controls.Button;
  import mx.core.Application;
  import mx.core.UIComponent;
  import mx.events.FlexEvent;

  import mx.controls.sliderClasses.Slider;
  import mx.controls.sliderClasses.SliderDirection;
  import mx.events.SliderEvent;

  public class VidPublish extends Application
  {
    private var connection:NetConnection = null;
    private var stream:NetStream = null;
    private var camera:Camera = Camera.getCamera();
    private var mic:Microphone = Microphone.getMicrophone();
    private var video:Video;

    private var st:SoundTransform = new SoundTransform();
    public var volume:Slider;

    public var button_audio     : Button;
    public var button_video	: Button;
    public var send_cb		: Boolean = true;
    public var send_au		: Boolean = true;

    public var connected        : Boolean = false;

    public var vid_width        : int;
    public var vid_height       : int;

    public var videoHolder	: UIComponent;
    //public var panel            : Panel;

    public var box : HBox;

    public var stream_name: String;
    public var stream_type: String;

    public function VidPublish()
    {
      super();
      this.addEventListener(FlexEvent.APPLICATION_COMPLETE, NetConnectionExample);
      stream_name = getparam("stream");
    }

    private function sliderChanged(e:SliderEvent):void {
      /* WARNING! do not set gain approximately below 80, in fact,
         try not to mess with it at all.  Flash (9.0 under linux)
         when there is no webcam gets really screwed up when gain
         or mute is set. */
      var vol:Number = Number(e.target.value) * 2.0 + 80.0;
      mic.gain = vol;
      trace(' Slider changed: ' + vol);
    }

    private function getparam(key:String, notfound:String=''): String
    {
      try
      {
        var keyStr:String;
        var valueStr:String;
        var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
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

    private function make_connection():void
    {
      connection = new FMSConnection();
      connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);

      connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
      connection.objectEncoding = ObjectEncoding.AMF0;
      connection.connect(getparam('server'), getparam('token', 'I_did_not_supply_a_token'));
      trace("made connection " + getparam('server') + " with token " + getparam('token', 'I_did_not_supply_a_token'));

      connected = true;
    }

    private function addVideo():void {
      //videoHolder = new UIComponent();
      vid_width = int(getparam("width", "640"));
      vid_height = int(getparam("height", "480"));

      video = new Video(vid_width, vid_height);
      videoHolder.addChild(video);
    }

    public function NetConnectionExample(event:FlexEvent):void
    {
      trace("NetConnectionExample");

      volume.direction = SliderDirection.VERTICAL;
      volume.minimum = 0;
      volume.maximum = 10;
      volume.liveDragging = true;
      volume.snapInterval = 1;
      volume.tickInterval = 2;
      volume.value = 5;
      volume.addEventListener(SliderEvent.CHANGE, sliderChanged);

      addVideo();

      videoHolder.width = vid_width;
      videoHolder.height = vid_height;
      videoHolder.setActualSize(vid_width, vid_height);
      var record : int = int(getparam("recordimmediately", "1"));
      stream_type = getparam("streamtype", "live");
      trace("stream type:" + stream_type);

      if (record)
        send_cb = true;
      else
        send_cb = false;

      trace("recording immediately:" + send_cb);
      make_connection();
    }

    private function connectStream():void {
      stream = new NetStream(connection);
      stream.addEventListener(NetStatusEvent.NET_STATUS, onStreamNetStatus);
      stream.bufferTime = 1;

      var record_width : int = int(getparam("recordwidth", "640"));
      var record_height : int = int(getparam("recordheight", "480"));
      var fps : int = int(getparam("fps", "15"));
      var audio_rate : int = int(getparam("audiorate", "22000"));
      var bandwidth : int = int(getparam("bandwidth", "0"));
      var quality : int = int(getparam("quality", "70"));
      var silence_level : int = int(getparam("silencelevel", "1"));

      videoHolder.width = vid_width;
      videoHolder.height = vid_height;
      videoHolder.setActualSize(vid_width, vid_height);
      videoHolder.x = 0;
      videoHolder.y = 0;

      mic.setSilenceLevel(silence_level);
      mic.rate = audio_rate;
      mic.gain = 90;

      if (camera != null) {

        camera.setMode(record_width, record_height, fps, false);
        camera.setQuality(bandwidth, quality); //  quality to 80%
        //camera.setMotionLevel(100); // do not do motion detection
        camera.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
        //video = new Video(camera.width * 2, camera.height * 2);
        video.attachCamera(camera);
        trace(connection.objectEncoding);
        trace("All added you should see video");
      }
      else
      {
        trace("you need a camera to publish video - audio should be fine");
      }
      stream.publish(stream_name, stream_type);
//			stream.pause();
    }

    private function connectVideo():void
    {
      stream.bufferTime = 1;
      stream.attachCamera(camera);
      stream.attachAudio(mic);
//			stream.resume();            public function catchVideos():void
      // call server-side method
      indicate_connected("1", stream_type);
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

    private function indicate_connected(is_connected:String, is_live:String):void
    {
      var user_name:String = getparam("user", "");

      if (user_name == "")
        return;

      var nc_responder:Responder = new Responder(online_publish_response, null);
      /* connection.call("demoService.userStreamConnected", nc_responder, user_name, stream_name,
         is_connected, is_live); */
    }

    public function online_publish_response (resp:int):void
    {
      trace("online_publish_response:" + String(resp));
    }

    private	function onStreamNetStatus(e:NetStatusEvent):void{
      trace("onStreamNetStatus: " + e.info.code);
      switch (e.info.code) {
      case "NetStream.Publish.Start":
        connectVideo();
        break;
      case "NetStream.Publish.BadName":
        disconnectStream();
        break;
      }
    }

    public function disconnectStream(): void
    {
      if (stream)
      {
        stream.attachCamera(null);
        stream.attachAudio(null);
        stream.close();
      }
      if (connection)
      {
        indicate_connected("0", stream_type);
        connection.close();
      }
      //delete connection;
      //delete stream;
      connection = null;
      stream = null;

      connected = false;
    }

    public function enableVideo(): void
    {
      if (connection && connection.connected && stream)
      {
        if (send_cb)
        {
          stream.attachCamera(camera);
          indicate_connected("1", stream_type);
        }
        else
        {
          stream.attachCamera(null);
          indicate_connected("0", stream_type);
        }
      }
      else
      {
        if (send_cb)
        {
          make_connection();
        }
        else
        {
          disconnectStream();
        }
      }
    }
    public function enableAudio(): void
    {
      if (connection && connection.connected && stream)
      {
        if (send_au)
          stream.attachAudio(mic);
        else
          stream.attachAudio(null);
      }
    }

    public function audio_toggle(): void
    {
      if (!send_au)
      {
        button_audio.styleName = "buttonaudioon";
        button_audio.toolTip = "Audio Off";
        send_au = true;
        enableAudio();
      }
      else
      {
        button_audio.styleName = "buttonaudiooff";
        button_audio.toolTip = "Audio On";
        send_au = false;
        enableAudio();
      }
    }
    public function video_toggle(): void
    {
      if (!send_cb)
      {
        button_video.styleName = "buttonvideoon";
        button_video.toolTip = "Video Off";
        send_cb = true;
        enableVideo();
      }
      else
      {
        button_video.styleName = "buttonvideooff";
        button_video.toolTip = "Video Off";

        send_cb = false;
        enableVideo();
      }
    }

    private function netStatusHandler(event:NetStatusEvent):void {
      trace("netStatusHandler " + event.info.code);
      switch (event.info.code) {
      case "NetConnection.Connect.Success":
        get_stream_name_and_connect();
        break;
      case "NetConnection.Connect.Failed":
      case "NetConnection.Connect.Closed":
        disconnectStream();
      if (send_cb) /* reconnect automatically if desired */
      {
        var myTimer:Timer = new Timer(5000, 1); // 5 seconds
        myTimer.addEventListener(TimerEvent.TIMER, runOnce);
        myTimer.start();
      }
      break;

      case "NetStream.Play.StreamNotFound":
        trace("Stream not found: ");
        break;
      }
    }

    private function runOnce(event:TimerEvent):void {
      trace("runOnce() called");
      make_connection();
    }

    private function securityErrorHandler(event:SecurityErrorEvent):void {
      trace("securityErrorHandler: " + event);
    }

    public function onMetaData(info:Object):void {
      trace("metadata: duration=" + info.duration + "width=" + info.width + " height=" + info.height + " framerate=" +
            info.framerate);
    }
    public function onCuePoint(info:Object):void {
      trace("cuepoint: time=" + info.time + " name=" +
            info.name + " type=" + info.type);
    }
    private function activityHandler(event:ActivityEvent):void {
      trace("activityHandler: " + event);
    }

  }
}
