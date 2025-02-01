# Silences plugin
Deal with silences timestamps and calculate real remaining time.

## Plugin options

* **fastRate** ``int``: Decide the speed of silences; if not set, is ``8``.
* **normalRate** ``int``: Decide the speed when there's no silence (can be changed later); if not set, is ``1``.
* **displayRealRemainingTime** ``boolean``: Decide if you want to display the real remaining time, calculated by this plugin. Default is ``true``.
* **onSkip** ``function (newTime)``: A function that will be called when a silence is skipped (by the user). Default is ``null``.

## New methods added to the player

* ``isInSilence()``: Return a boolean that indicates if the player is currently crossing a silence. 
* ``skipCurrentSilence()``: Skip the current silence if exists, and call ``onSkip`` if set.
* ``setNormalRate(newNormalRate)``: Change the current normal rate. To be called when the user change the player's speed.
* ``getNormalRate()``: Return the current normal rate.
* ``getFastRate()``: Return the fast rate.
* ``shouldDisplayRealRemainingTime(should)``: Decide if you want to display the real remaining time (``true``), or the default player's remaining time (``false``).
* ``setSilenceTimestamps(timestamps)``: Update the silence timestamps (to be called when timestamps change or the video itself change). ``timestamps`` is an array of objects ``{t_start, t_end}``.
