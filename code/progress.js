let total;
let completed;
let currentVideo;
let currentStatus;
let progressBar;

window.onload = () => {
  total = document.getElementById("total");
  completed = document.getElementById("completed");
  currentVideo = document.getElementById("currentVideo");
  currentStatus = document.getElementById("currentStatus");
  progressBar = document.getElementById("progressBar");

  document.getElementById("maximize").addEventListener("click", (event) => {
    ipc.send("viewMainWindow");
  });
}

ipc.on("changeTotal", (event, value) => {
  total.innerHTML = "/" + value;
});

ipc.on("changeCompleted", (event, value) => {
  completed.innerHTML = value;
});

ipc.on("changeName", (event, value) => {
  currentVideo.innerHTML = value;
});

ipc.on("changeStatus", (event, value) => {
  currentStatus.innerHTML = value;
});

ipc.on("changeProgressBar", (event, value) => {
  progressBar.style.width = value + "%";
});
