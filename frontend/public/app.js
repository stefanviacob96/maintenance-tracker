const API = window.APP_CONFIG.API_URL;

async function loadAssets() {
  const res = await fetch(API + "/assets");
  const data = await res.json();

  const list = document.getElementById("assets-list");
  list.innerHTML = "";

  data.assets.forEach(a => {
    const li = document.createElement("li");
    li.innerText = `${a.id} - ${a.name}`;
    list.appendChild(li);
  });
}

async function createTask() {
  const asset_id = document.getElementById("asset_id").value;
  const title = document.getElementById("title").value;
  const frequency_days = parseInt(document.getElementById("frequency").value);

  await fetch(API + "/tasks", {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({ asset_id, title, frequency_days })
  });

  alert("Task created");
}

async function completeTask() {
  const task_id = document.getElementById("task_id").value;
  const completed_at = document.getElementById("date").value;

  await fetch(API + `/tasks/${task_id}/complete`, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({ completed_at })
  });

  alert("Task completed");
}

async function loadTasks() {
  const res = await fetch(API + "/tasks");
  const data = await res.json();

  const list = document.getElementById("tasks-list");
  list.innerHTML = "";

  data.tasks.forEach(t => {
    const li = document.createElement("li");
    li.innerText = `${t.id} - ${t.title} (next: ${t.next_due_date})`;
    list.appendChild(li);
  });
}

async function runCheck() {
  const script = document.getElementById("script-select").value;

  const response = await fetch(`${API}/jobs`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ script })
  });

  const data = await response.json();
  const taskId = data.task_id;

  document.getElementById("job-result").innerHTML =
    `Status: <span class="pending">PENDING</span>\nJob started: ${taskId}`;

  pollJob(taskId);
}

async function pollJob(taskId) {
  const resultBox = document.getElementById("job-result");

  const intervalId = setInterval(async () => {
    const response = await fetch(`${API}/jobs/${taskId}`);
    const data = await response.json();

    let statusClass = "pending";
    if (data.status === "SUCCESS") statusClass = "success";
    if (data.status === "FAILURE") statusClass = "error";

    resultBox.innerHTML = `<h3 class="${statusClass}">Status: ${data.status}</h3><pre>${JSON.stringify(data, null, 2)}</pre>`;

    if (data.status === "SUCCESS" || data.status === "FAILURE") {
      clearInterval(intervalId);
    }
  }, 1000);
}

async function loadJobHistory() {
  const container = document.getElementById("job-history");

  const response = await fetch(`${API}/jobs/history`);
  const data = await response.json();

  if (!Array.isArray(data)) {
    container.innerHTML = "<p>Error loading history</p>";
    return;
  }

  let html = "<table border='1' cellpadding='5'>";
  html += "<tr><th>ID</th><th>Script</th><th>Status</th><th>Result</th><th>Created</th></tr>";

  data.forEach((job, index) => {
    let color = "black";
    if (job.status === "SUCCESS") color = "green";
    if (job.status === "FAILED") color = "red";

    html += `
      <tr style="${index === 0 ? 'background-color: #f0f8ff; font-weight: bold;' : ''}">
        <td>${job.id}</td>
        <td>${job.script}</td>
        <td style="color:${color}">${job.status}</td>
        <td>${job.result || ""}</td>
        <td>${job.created_at}</td>
      </tr>
    `;
  });

  html += "</table>";

  container.innerHTML = html;
}

setInterval(loadJobHistory, 5000);


