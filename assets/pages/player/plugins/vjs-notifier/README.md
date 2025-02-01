# Notifier plugin
Notify short messages at the top right of the video.

## Plugin options

* **defaultTimeout** ``int``: Milliseconds after which the message disappears; if not set, is: ``1500``.

## New methods added to the player

* ``notify(text, timeout)``: Display the message. The text can be html (use with wisdom), and the timeout is optional (refer to *defaultTimeout*).
