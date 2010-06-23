package com.renaun.samples.net
{
  import flash.net.NetConnection;
  import flash.net.SharedObject;
  import flash.events.NetStatusEvent;
  import flash.events.SecurityErrorEvent;
  import flash.events.AsyncErrorEvent;
  import flash.events.IOErrorEvent
    import flash.events.Event;
  import flash.events.IEventDispatcher;


  [Event(name="success", type="flash.events.Event")]
    [Event(name="failed", type="flash.events.Event")]
/**
 * 	Note: This class was dynamic in ActionScript 2.0 but is now sealed.
 *  To write callback methods for this class, you can either extend the
 *  class and define the callback methods in your subclass, or you can
 *  use the client  property to refer to an object and define the callback
 *  methods on that object.
 */
    dynamic public class FMSConnection extends NetConnection implements IEventDispatcher
    {

      //--------------------------------------------------------------------------
      //
      //  Constructor
      //
      //--------------------------------------------------------------------------

      /**
       *  Constructor
       */
      public function FMSConnection()
      {
        super();

      }

      public var clientID:Number;

      //--------------------------------------------------------------------------
      //
      //  Methods
      //
      //--------------------------------------------------------------------------

      /**
       *  Connect
       */
      override public function connect( url:String, ...args ):void
      {
        // Set object encoding to be compatible with Flash Media Server
        this.objectEncoding = flash.net.ObjectEncoding.AMF0;
        NetConnection.defaultObjectEncoding

          // Add status/security listeners
          this.addEventListener( NetStatusEvent.NET_STATUS, netStatusHandler );
        this.addEventListener( SecurityErrorEvent.SECURITY_ERROR, netSecurityError );
        this.addEventListener( AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler );
        this.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );

        // TODO does not pass ...args into the super function
        super.connect( url, args );
      }


      /**
       *  setID
       */
      public function setId( id:Number ):*
      {
//Logger.debug( "FMSConnection::setId: id=" + id );
        if( isNaN( id ) ) return;
        clientID = id;
        return "Okay";
      }

      /**
       * 	Status Handler for the NetConnection class
       */
      private function netStatusHandler( event:NetStatusEvent ):void
      {
        switch( event.info.code ) {
        case "NetConnection.Connect.Success":
//Logger.debug( "FMSConnection:netStatusHandler:Success: connected: " + this.connected );
          dispatchEvent( new Event( "success" ) );
          break;
        case "NetConnection.Connect.Failed":
//Logger.debug( "FMSConnection:netStatusHandler:Failed: connected: " + this.connected + " - " + event.info.code );
          dispatchEvent( new Event( "failed" ) );
          break;
        default:
//Logger.debug( "FMSConnection:netStatusHandler:code: " + event.info.code );
          break;
        }
      }

      private function netSecurityError( event:SecurityErrorEvent ):void {
//Logger.error( "FMSConnection:netSecurityError: " + event );
      }

      private function asyncErrorHandler( event:AsyncErrorEvent ):void {
//Logger.error( "FMSConnection:asyncErrorHandler: " + event.type + " - " + event.error );
      }

      private function ioErrorHandler( event:IOErrorEvent ):void {
//Logger.error( "FMSConnection:asyncErrorHandler: " + event.type + " - " + event.text );
      }

    }
}
