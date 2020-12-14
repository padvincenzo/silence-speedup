<p>
FFmpeg binaries not included in this repository (but they are included in zip releases);
you can download them from:
</p>

<ul>
<li>Windows: <a href="https://www.gyan.dev/ffmpeg/builds/" target="_blank">www.gyan.dev</a></li>
<li>Mac: <a href="https://evermeet.cx/ffmpeg/" target="_blank">evermeet.cx</a></li>
<li>Linux: <a href="https://www.johnvansickle.com/ffmpeg/" target="_blank">www.johnvansickle.com</a></li>
</ul>

<p>
Of course you can install FFmpeg on your computer (or you have it already installed), and want to use it.
If it's so, you need to make small changes to the file (source code path)/assets/classes/ffmpeg.js:
</p>

<ol>
<li>Go to the method static load()</li>
<li>Comment code block(s) that refers to ffmpeg static binaries</li>
<li>Set FFmpeg.command to the path of your ffmpeg executable, or the command that call it.</li>
</ol>
