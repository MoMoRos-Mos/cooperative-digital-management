// Call Variable where to send Data/API
const API_BASE =
    "http://127.0.0.1:8000";

// Call variable can change value anytime by : let
let allMembers = [];
let editingMemberId = null;

// FUNCTION: Load data to dashboard
async function loadDashboard() {

    const response = await fetch(
        `${API_BASE}/dashboard/summary`
    );

    const data = await response.json();

    document.getElementById(
        "total-member"
    ).textContent =
        `${data.total_member} คน `;

    document.getElementById(
        "active-member"
    ).textContent =
        `${data.active_members} คน`;

    document.getElementById(
        "inactive-member"
    ).textContent =
        `${data.inactive_members} คน`;

    document.getElementById(
        "total-deposit"
    ).textContent =
        `${Number(data.total_deposit).toLocaleString()} ฿`;

    document.getElementById(
        "total-principal"
    ).textContent =
        `${Number(data.total_loan_principal).toLocaleString()} ฿`;

    document.getElementById(
        "total-principal-paid"
    ).textContent =
        `${Number(data.total_principal_paid).toLocaleString()} ฿`;

    document.getElementById(
        "outstanding"
    ).textContent =
        `${Number(data.outstanding_principal).toLocaleString()} ฿`;

}

// FUNCTION: load members data all and set to Variable: allMembers
async function loadMembers() {

    const response =
        await fetch(
            `${API_BASE}/members`
        );

    allMembers =
        await response.json();

    renderMembers(allMembers);
}

// FUNCTION: Load all member create to table by use Arguiment variable: allMembers
function renderMembers(member) {

    const tbody = document.getElementById("member-table-body");
    tbody.innerHTML = "";

    member.forEach(member => {
        const row = document.createElement("tr");

        row.innerHTML = `
        <td>${member.member_id}</td>
        <td>${member.member_no}</td>
        <td>${member.full_name}</td>
        <td>${member.department ?? "-"}</td>
        
        <td>
            <span class="status-badge ${member.status.toLowerCase()}">
            ${member.status === "ACTIVE" ? '<i class="bi bi-check-circle-fill"></i>' : '<i class="bi bi-x-circle-fill"></i>'}
              ${member.status}
            </span>
        </td>

        <td>
            <button
                onclick="editMember(${member.member_id})"
                class="action-btn action-edit"
                type="button"
            >
            <i class="bi bi-pencil-square"></i> Edit
            </button>
            
            <button
                onclick="deactivateMember(${member.member_id})"
                ${member.status !== "ACTIVE" ? "disabled" : ""}
                 class="action-btn action-deactivate"
                 type="button"
            >
            <i class="bi bi-trash3-fill"></i> Deactivate
            </button>
        </td>
        `;
        tbody.appendChild(row);
    });
}

// FUNCTION: Edit member select get data to form and change mode to edit
function editMember(memberId) {

    const selectedMember = allMembers.find(member => member.member_id === memberId);
    if (!selectedMember) {
        return;
    }

    editingMemberId = memberId;

    document.getElementById("member-no").value = selectedMember.member_no;
    document.getElementById("member-no").disabled = true;
    document.getElementById("full-name").value = selectedMember.full_name;
    document.getElementById("department").value = selectedMember.department ?? "";
    document.getElementById("join-date").value = selectedMember.join_date;
    document.getElementById("status").value = selectedMember.status;

    // เปลี่ยนมาใช้ innerHTML เพื่อใส่ไอคอน
    document.getElementById("member-submit-button").innerHTML = "<i class='bi bi-save'></i> Update Member";
    document.getElementById("member-form-title").innerHTML = "Edit Member <i class='bi bi-pencil-square'></i>";
    document.getElementById("cancel-edit-button").innerHTML = "<i class='bi bi-x-circle'></i> Cancel Edit";
}

// FUNCTION: Delete member
async function deactivateMember(memberId) {

    // Check member select status is "ACTIVE"
    const targetMember = allMembers.find(member => member.member_id === memberId);

    // Check have member
    if (!targetMember) {
        console.log("Deactivate member failed: Member not found");
        ShowToast("<i class='bi bi-person-x-fill text-danger'></i> ไม่พบผู้ใช้งาน");
        return;
    }

    // Check status
    if (targetMember.status !== "ACTIVE") {
        alert("Member is not ACTIVE:");
        ShowToast("<i class='bi bi-exclamation-triangle-fill text-warning'></i> ผู้ใช้งานอยู่ในสถานะ INACTIVE แล้ว");
        return;
    }

    // Create confirm popup
    const confirmed = confirm(`คุณต้องการปิดการใช้งานสมาชิก ID ${memberId} หรือไม่?`);

    // Check confirm result
    if (!confirmed) {
        console.log("Cancel deactivate member:");
        ShowToast("<i class='bi bi-info-circle-fill text-secondary'></i> ยกเลิกการทำรายการแล้ว");
        return;
    }

    // Create FastAPI to Delete
    const response = await fetch(`${API_BASE}/members/${memberId}`, {
        method: "DELETE"
    });

    // Check delete result
    if (!response.ok) {
        const errorData = await response.json();
        console.log("Deactivate member failed:", errorData);
        ShowToast("<i class='bi bi-x-circle-fill text-danger'></i> เปลี่ยนสถานะไม่สำเร็จ");
        return;
    }

    // If success
    const result = await response.json();

    // Show toast here
    ShowToast(`<i class='bi bi-check-circle-fill text-success'></i> ยกเลิกการใช้งานสมาชิก ID ${memberId} แล้ว`);
    console.log("Member deactivated:", result);

    // Clear from
    ResetMemberForm();
    // Refresh website
    await loadMembers();
    await loadDashboard();
} // <-- นี่คือวงเล็บปิดฟังก์ชันที่ถูกต้อง ต้องอยู่ตรงนี้ครับ!

// FUNCTION : Set up cancel edit button & Connect button event
function SetupCancelEdit() {

    const CancelButton =
        document.getElementById(
            "cancel-edit-button"
        );

    CancelButton.addEventListener(
        "click",
        function () {

            // Check Mode ADD OR EDIT
            if (editingMemberId === null) {

                // Get data in forms
                const memberNo = document.getElementById("member-no").value.trim();
                const fullName = document.getElementById("full-name").value.trim();
                const department = document.getElementById("department").value.trim();
                const joinDate = document.getElementById("join-date").value;

                if (!memberNo && !fullName && !department && !joinDate) {
                    alert("The form is empty");
                    console.log("Form is empty, Can't clear:");
                    return;
                }

                console.log("Clear form success:");

            } else {
                console.log("Cancel add member:")
            }

            // Clear form
            ResetMemberForm();

        }
    );
}

// FUNCTION : Back to add member mode reset everything in form set editingMemberId = null;
function ResetMemberForm() {

    editingMemberId = null;
    document.getElementById("add-member-form").reset();
    document.getElementById("member-no").disabled = false;

    // เปลี่ยนมาใช้ innerHTML เพื่อใส่ไอคอน
    document.getElementById("member-form-title").innerHTML = "Add Member <i class='bi bi-person-vcard'></i>";
    document.getElementById("member-submit-button").innerHTML = "Add Member <i class='bi bi-person-vcard'></i>";
    document.getElementById("cancel-edit-button").innerHTML = "<i class='bi bi-eraser'></i> Clear Form";
}

// FUNCTION: Show toast
function ShowToast(message) {
    const toast = document.getElementById("custom-toast");

    // เปลี่ยนจาก textContent เป็น innerHTML
    toast.innerHTML = message;
    toast.hidden = false;

    setTimeout(function () {
        toast.hidden = true;
    }, 3000);
}

// FUNCTION: Set up search system
function setupMemberSearch() {
    const searchInput =
        document.getElementById(
            "member-search"
        );

    searchInput.addEventListener(
        "input",
        function () {

            const keyword =
                searchInput.value
                    .toLowerCase()
                    .trim();

            const filterMembers =
                allMembers.filter(member => {

                    return (
                        member.member_no
                            .toLowerCase()
                            .includes(keyword)

                        ||

                        member.full_name
                            .toLowerCase()
                            .includes(keyword)

                        ||

                        (member.department ?? "")
                            .toLowerCase()
                            .includes(keyword)

                        ||

                        member.status
                            .toLowerCase()
                            .includes(keyword)
                    );

                });

            renderMembers(
                filterMembers
            );
        }
    );
}

// FUNCTION: Set up add member button event and input box in form
function setupAddMemberForm() {

    const form =
        document.getElementById(
            "add-member-form"
        );

    form.addEventListener(
        "submit",
        async function (event) {

            event.preventDefault();
            SetSubmitLoading(true);

            const memberData = {

                member_no:
                    document.getElementById(
                        "member-no"
                    ).value.trim(),

                full_name:
                    document.getElementById(
                        "full-name"
                    ).value.trim(),

                department:
                    document.getElementById(
                        "department"
                    ).value.trim(),

                join_date:
                    document.getElementById(
                        "join-date"
                    ).value,

                status:
                    document.getElementById(
                        "status"
                    ).value
            };

            // Show Create member success
            console.log(
                "Set member data to update",
                memberData
            )

            let url;
            let method;
            let requestData;

            // Change Mode Edit member / Add member
            if (editingMemberId === null) {

                url = `${API_BASE}/members`;
                method = "POST";

                requestData =
                    memberData;

            } else {
                url = `${API_BASE}/members/${editingMemberId}`;
                method = "PUT";

                requestData = {
                    full_name:
                        memberData.full_name,
                    department:
                        memberData.department,
                    join_date:
                        memberData.join_date,
                    status:
                        memberData.status
                };
            }

            console.log(
                "Mode:",
                method,
                url,
                requestData
            );

            // Create result of work : add member?
            const response =
                await fetch(
                    url,
                    {
                        method: method,

                        headers: {
                            "Content-Type":
                                "application/json"
                        },

                        body:
                            JSON.stringify(
                                requestData
                            )
                    }
                );

            // If result of work not return ok : Not success , Stop working in this logic by return;
            if (!response.ok) {
                const errorData = await response.json();
                console.error("Save member failed:", errorData);
                ShowToast("<i class='bi bi-x-circle-fill text-danger'></i> บันทึกข้อมูลไม่สำเร็จ");
                SetSubmitLoading(false);
                return;
            }

            // If success work new: Create variable data member save success.
            const SaveMember =
                await response.json();

            // Show in console.loh save success and show member data in json table data
            console.log(
                "Member saved:",
                SaveMember
            );

            if (editingMemberId === null) {
                ShowToast("<i class='bi bi-check-circle-fill text-success'></i> เพิ่มสมาชิกเรียบร้อยแล้ว");
            } else {
                ShowToast("<i class='bi bi-check-circle-fill text-success'></i> แก้ไขสมาชิกเรียบร้อยแล้ว");
            }

            // When work is success Refresh Member form for show new data
            ResetMemberForm();

            // load new members and refresh dashboard
            await loadMembers();
            await loadDashboard();

            // Unblock button
            SetSubmitLoading(false);

        }
    );

}

// FUNCTION: Loading 
function SetSubmitLoading(isLoading) {

    const button = document.getElementById("member-submit-button");
    button.disabled = isLoading;

    if (isLoading) {
        button.innerHTML = "<i class='bi bi-hourglass-split'></i> Loading...";
    } else {
        if (editingMemberId === null) {
            button.innerHTML = "Add Member <i class='bi bi-person-vcard'></i>";
        } else {
            button.innerHTML = "<i class='bi bi-save'></i> Update Member";
        }
    }
}

// MAIN FUNCTION: Start app run all function to work
async function startApp() {

    try {

        await Promise.all([
            loadDashboard(),
            loadMembers()
        ]);

        setupMemberSearch();
        setupAddMemberForm();
        SetupCancelEdit();

    } catch (error) {

        console.error(
            "Cannot load application",
        );

    }
}

// Call Main Function
startApp();
