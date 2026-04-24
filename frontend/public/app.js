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
