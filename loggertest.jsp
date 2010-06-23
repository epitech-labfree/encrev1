<%@page import="org.slf4j.Logger,
org.slf4j.LoggerFactory,
org.slf4j.impl.StaticLoggerBinder,
ch.qos.logback.classic.LoggerContext,
org.red5.logging.LoggingContextSelector,
org.red5.logging.Red5LoggerFactory"%>
<html>
<body>
<%
Logger log = Red5LoggerFactory.getLogger(this.getClass()); //"TestJsp");
log.info("This is a test log entry from a web context");

//
LoggingContextSelector selector = (LoggingContextSelector) StaticLoggerBinder.getSingleton().getContextSelector();
LoggerContext ctx = selector.getLoggerContext("encrev1");
Logger log2 = ctx.getLogger("TestJsp");
log2.info("This is a test log entry from a web context attempt 2");


for (int i = 0; i < 10; i++) {
    out.print(i);
    out.print("<br />");
}
%>
</body>
</html>

