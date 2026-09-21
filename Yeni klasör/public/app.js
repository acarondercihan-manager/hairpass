// State Management
const defaultState = {
  salon: {
    name: "Golden Scissor Premium Kuaför",
    logoText: "✂️ GS",
    logoUrl: "",
    phone: "0532 555 10 20",
    address: "Bağdat Caddesi No:142, Kadıköy / İstanbul",
    openTime: "09:00",
    closeTime: "19:00",
    lunchStart: "12:30",
    lunchEnd: "13:30"
  },
  services: [
    { id: 1, name: "Saç Kesimi & Yıkama", durationMinutes: 30, price: 400, category: "Saç" },
    { id: 2, name: "Sakal Tıraşı & Bakım", durationMinutes: 15, price: 200, category: "Sakal" },
    { id: 3, name: "Saç + Sakal Özel Paketi", durationMinutes: 45, price: 550, category: "Paket" },
    { id: 4, name: "Saç Boyama & Renklendirme", durationMinutes: 90, price: 1200, category: "Boya" },
    { id: 5, name: "Keratin & Saç Bakımı", durationMinutes: 60, price: 850, category: "Bakım" }
  ],
  staff: [
    {
      id: 1,
      name: "Ahmet Usta",
      title: "Baş Kuaför",
      phone: "0532 111 22 33",
      avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face",
      allowedServices: [1, 2, 3, 4, 5],
      permissions: {
        canViewCustomerPhone: true,
        canCancelAppointments: true,
        canAddManualBreaks: true,
        canEditPrices: true
      }
    },
    {
      id: 2,
      name: "Mehmet Kalfa",
      title: "Erkek Kuaförü",
      phone: "0533 222 33 44",
      avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      allowedServices: [1, 2, 3], // Boya ve keratin yetkisi yok
      permissions: {
        canViewCustomerPhone: false, // Telefon gizleme yetkisi
        canCancelAppointments: true,
        canAddManualBreaks: true,
        canEditPrices: false
      }
    },
    {
      id: 3,
      name: "Ayşe Hanım",
      title: "Renklendirme & Bakım Uzmanı",
      phone: "0535 333 44 55",
      avatar: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&h=150&fit=crop&crop=face",
      allowedServices: [1, 4, 5],
      permissions: {
        canViewCustomerPhone: true,
        canCancelAppointments: false,
        canAddManualBreaks: true,
        canEditPrices: false
      }
    }
  ],
  appointments: [],
  chats: {},
  // Zaman simülasyonu için sanal saat ofseti
  timeTravelOffsetHours: 0
};

// LocalStorage'dan yükle veya varsayılanı kullan
let state = JSON.parse(localStorage.getItem('kuafor_system_state') || 'null');
if (!state || !state.salon) {
  state = defaultState;
  // Başlangıç için örnek bir randevu oluşturalım (Bugün saat 16:00'a)
  const todayStr = new Date().toISOString().split('T')[0];
  state.appointments.push({
    id: "APT-101",
    salonId: 1,
    staffId: 1,
    customerName: "Caner Yılmaz",
    customerPhone: "0542 987 65 43",
    services: [state.services[0]], // Saç Kesimi (30 dk)
    totalDuration: 30,
    totalPrice: 400,
    date: todayStr,
    startTime: "16:00",
    endTime: "16:30",
    status: "ONAYLANDI",
    createdAt: new Date().toISOString()
  });

  // Örnek mesajlar
  state.chats["APT-101"] = [
    { sender: "MUSTERI", text: "Merhaba Ahmet Usta, bugün 16:00'da randevum var.", time: "11:30" },
    { sender: "PERSONEL", text: "Merhaba Caner Bey, bekliyorum hoş geldiniz şimdiden!", time: "11:35" }
  ];
  saveState();
}

function saveState() {
  localStorage.setItem('kuafor_system_state', JSON.stringify(state));
}

function resetToDefault() {
  if (confirm("Tüm veriler varsayılan fabrika ayarlarına sıfırlansın mı?")) {
    localStorage.removeItem('kuafor_system_state');
    location.reload();
  }
}

// Global UI State
let currentRole = "dual"; // admin, staff, customer, dual
let selectedStaffId = 1;
let selectedServiceIds = [1];
let selectedDate = new Date().toISOString().split('T')[0];
let selectedSlot = null;
let activeStaffTab = "agenda"; // agenda, chat, permissions
let activeCustomerTab = "booking"; // booking, my-appointments, chat
let activeChatAppointmentId = "APT-101";

// DOM Yüklendiğinde Başlat
document.addEventListener('DOMContentLoaded', () => {
  setupEventListeners();
  renderAllViews();
});

function setupEventListeners() {
  // Rol değiştirici butonları
  document.querySelectorAll('.role-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const role = e.currentTarget.dataset.role;
      switchRoleView(role);
    });
  });

  // Admin Salon Formu
  const salonForm = document.getElementById('admin-salon-form');
  if (salonForm) {
    salonForm.addEventListener('submit', (e) => {
      e.preventDefault();
      state.salon.name = document.getElementById('adm-salon-name').value;
      state.salon.phone = document.getElementById('adm-salon-phone').value;
      state.salon.address = document.getElementById('adm-salon-address').value;
      state.salon.openTime = document.getElementById('adm-open-time').value;
      state.salon.closeTime = document.getElementById('adm-close-time').value;
      state.salon.logoUrl = document.getElementById('adm-logo-url').value;
      saveState();
      showToast("Salon bilgileri ve çalışma saatleri güncellendi!");
      renderAllViews();
    });
  }

  // Admin Hizmet Ekleme Formu
  const serviceForm = document.getElementById('admin-service-form');
  if (serviceForm) {
    serviceForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('srv-name').value;
      const duration = parseInt(document.getElementById('srv-duration').value);
      const price = parseFloat(document.getElementById('srv-price').value);
      const category = document.getElementById('srv-category').value;
      
      const newId = state.services.length > 0 ? Math.max(...state.services.map(s => s.id)) + 1 : 1;
      state.services.push({ id: newId, name, durationMinutes: duration, price, category });
      // Yeni hizmeti Baş Kuaföre otomatik ekle
      state.staff[0].allowedServices.push(newId);

      saveState();
      serviceForm.reset();
      showToast(`"${name}" hizmeti (${duration} dk) başarıyla eklendi!`);
      renderAllViews();
    });
  }

  // Admin Çalışan Ekleme Formu
  const staffForm = document.getElementById('admin-staff-form');
  if (staffForm) {
    staffForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('stf-name').value;
      const title = document.getElementById('stf-title').value;
      const phone = document.getElementById('stf-phone').value;
      
      const newId = state.staff.length > 0 ? Math.max(...state.staff.map(s => s.id)) + 1 : 1;
      state.staff.push({
        id: newId,
        name,
        title,
        phone,
        avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop&crop=face",
        allowedServices: [state.services[0].id],
        permissions: {
          canViewCustomerPhone: false,
          canCancelAppointments: true,
          canAddManualBreaks: true,
          canEditPrices: false
        }
      });

      saveState();
      staffForm.reset();
      showToast(`Yeni çalışan "${name}" sisteme eklendi!`);
      renderAllViews();
    });
  }
}

function switchRoleView(role) {
  currentRole = role;
  document.querySelectorAll('.role-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.role === role);
  });

  const viewDual = document.getElementById('view-dual');
  const viewAdmin = document.getElementById('view-admin');
  const cardCustomer = document.getElementById('card-customer');
  const cardStaff = document.getElementById('card-staff');

  if (role === 'admin') {
    if (viewDual) viewDual.classList.remove('active');
    if (viewAdmin) viewAdmin.classList.add('active');
  } else {
    if (viewAdmin) viewAdmin.classList.remove('active');
    if (viewDual) viewDual.classList.add('active');

    if (role === 'dual') {
      if (cardCustomer) cardCustomer.style.display = 'flex';
      if (cardStaff) cardStaff.style.display = 'flex';
    } else if (role === 'customer') {
      if (cardCustomer) cardCustomer.style.display = 'flex';
      if (cardStaff) cardStaff.style.display = 'none';
    } else if (role === 'staff') {
      if (cardCustomer) cardCustomer.style.display = 'none';
      if (cardStaff) cardStaff.style.display = 'flex';
    }
  }

  renderAllViews();
}

function renderAllViews() {
  renderAdminView();
  renderStaffView();
  renderCustomerView();
}

// ==========================================
// 1. ADMIN PANELİ İŞLEMLERİ
// ==========================================
function renderAdminView() {
  // Salon formu değerlerini doldur
  const nameInput = document.getElementById('adm-salon-name');
  if (nameInput) {
    nameInput.value = state.salon.name;
    document.getElementById('adm-salon-phone').value = state.salon.phone;
    document.getElementById('adm-salon-address').value = state.salon.address;
    document.getElementById('adm-open-time').value = state.salon.openTime;
    document.getElementById('adm-close-time').value = state.salon.closeTime;
    document.getElementById('adm-logo-url').value = state.salon.logoUrl || '';
  }

  // Hizmet Listesi
  const srvList = document.getElementById('admin-services-list');
  if (srvList) {
    srvList.innerHTML = state.services.map(s => `
      <div class="card" style="display: flex; justify-content: space-between; align-items: center; padding: 8px 12px; margin-bottom: 6px;">
        <div>
          <strong style="font-size: 13px;">${s.name}</strong>
          <div style="font-size: 11px; color: #64748b;">⏳ Süre: <b>${s.durationMinutes} dk</b> | Kategori: ${s.category}</div>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <span style="font-weight: 700; color: var(--primary); font-size: 13px;">${s.price} ₺</span>
          <button onclick="deleteService(${s.id})" style="background: none; border: none; color: #ef4444; cursor: pointer; font-size: 14px;" title="Sil">🗑️</button>
        </div>
      </div>
    `).join('');
  }

  // Çalışanlar ve Yetkilendirme Matrisi
  const permTableBody = document.getElementById('admin-permissions-body');
  if (permTableBody) {
    permTableBody.innerHTML = state.staff.map(st => {
      const allowedSrvNames = state.services
        .filter(srv => st.allowedServices.includes(srv.id))
        .map(srv => srv.name)
        .join(', ');

      return `
        <tr>
          <td>
            <div style="display: flex; align-items: center; gap: 8px;">
              <img src="${st.avatar}" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;">
              <div>
                <strong>${st.name}</strong>
                <div style="font-size: 10px; color: #64748b;">${st.title}</div>
              </div>
            </div>
          </td>
          <td>
            <div style="max-width: 180px; font-size: 11px; color: #334155;">
              ${allowedSrvNames || '<i style="color:#ef4444;">Yetkili hizmet yok</i>'}
            </div>
            <button onclick="openServicePermissionModal(${st.id})" style="font-size: 10px; color: var(--primary); background: none; border: none; cursor: pointer; text-decoration: underline; margin-top: 4px;">Hizmetleri Düzenle</button>
          </td>
          <td style="text-align: center;">
            <label class="switch">
              <input type="checkbox" ${st.permissions.canViewCustomerPhone ? 'checked' : ''} onchange="togglePermission(${st.id}, 'canViewCustomerPhone')">
              <span class="slider"></span>
            </label>
          </td>
          <td style="text-align: center;">
            <label class="switch">
              <input type="checkbox" ${st.permissions.canCancelAppointments ? 'checked' : ''} onchange="togglePermission(${st.id}, 'canCancelAppointments')">
              <span class="slider"></span>
            </label>
          </td>
          <td style="text-align: center;">
            <label class="switch">
              <input type="checkbox" ${st.permissions.canAddManualBreaks ? 'checked' : ''} onchange="togglePermission(${st.id}, 'canAddManualBreaks')">
              <span class="slider"></span>
            </label>
          </td>
          <td>
            <button onclick="deleteStaff(${st.id})" style="background: none; border: none; color: #ef4444; cursor: pointer;" title="Çalışanı Çıkar">❌</button>
          </td>
        </tr>
      `;
    }).join('');
  }
}

function togglePermission(staffId, permKey) {
  const staff = state.staff.find(s => s.id === staffId);
  if (staff) {
    staff.permissions[permKey] = !staff.permissions[permKey];
    saveState();
    showToast(`${staff.name} için yetki güncellendi!`);
    renderAllViews();
  }
}

function openServicePermissionModal(staffId) {
  const staff = state.staff.find(s => s.id === staffId);
  if (!staff) return;

  const choices = state.services.map(srv => {
    const isChecked = staff.allowedServices.includes(srv.id);
    return `
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #f1f5f9;">
        <span>${srv.name} (${srv.durationMinutes} dk)</span>
        <input type="checkbox" ${isChecked ? 'checked' : ''} onchange="toggleStaffService(${staff.id}, ${srv.id})">
      </div>
    `;
  }).join('');

  const modalHtml = `
    <div id="modal-backdrop" style="position: fixed; top:0; left:0; right:0; bottom:0; background: rgba(0,0,0,0.6); z-index: 10000; display: flex; align-items: center; justify-content: center;">
      <div style="background: #fff; width: 340px; border-radius: 12px; padding: 20px; box-shadow: 0 20px 25px rgba(0,0,0,0.2);">
        <h3 style="font-size: 15px; margin-bottom: 12px;">✂️ ${staff.name} - Hizmet Yetkileri</h3>
        <p style="font-size: 11px; color: #64748b; margin-bottom: 14px;">Çalışanın yapabileceği ve müşterilerin ondan randevu alabileceği işlemleri seçin:</p>
        <div style="max-height: 240px; overflow-y: auto; margin-bottom: 16px;">
          ${choices}
        </div>
        <button onclick="document.getElementById('modal-backdrop').remove()" class="btn-primary">Kapat ve Kaydet</button>
      </div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', modalHtml);
}

function toggleStaffService(staffId, serviceId) {
  const staff = state.staff.find(s => s.id === staffId);
  if (!staff) return;

  const idx = staff.allowedServices.indexOf(serviceId);
  if (idx > -1) {
    staff.allowedServices.splice(idx, 1);
  } else {
    staff.allowedServices.push(serviceId);
  }
  saveState();
  renderAllViews();
}

function deleteService(id) {
  if (confirm("Bu hizmeti silmek istediğinizden emin misiniz?")) {
    state.services = state.services.filter(s => s.id !== id);
    state.staff.forEach(st => {
      st.allowedServices = st.allowedServices.filter(sid => sid !== id);
    });
    saveState();
    renderAllViews();
  }
}

function deleteStaff(id) {
  if (confirm("Bu çalışanı silmek istediğinizden emin misiniz?")) {
    state.staff = state.staff.filter(s => s.id !== id);
    saveState();
    renderAllViews();
  }
}

// ==========================================
// 2. KUAFÖR ÇALIŞANI PANELİ (MOBİL)
// ==========================================
function renderStaffView() {
  const staffSelectDropdown = document.getElementById('staff-role-switcher-select');
  if (staffSelectDropdown) {
    staffSelectDropdown.innerHTML = state.staff.map(st => `
      <option value="${st.id}" ${st.id === selectedStaffId ? 'selected' : ''}>${st.name} (${st.title})</option>
    `).join('');
  }

  const currentStaff = state.staff.find(s => s.id === selectedStaffId) || state.staff[0];
  if (!currentStaff) return;

  // Header bilgisi
  const staffNameElem = document.getElementById('staff-active-name');
  if (staffNameElem) {
    staffNameElem.innerText = currentStaff.name;
    document.getElementById('staff-active-title').innerText = currentStaff.title;
    document.getElementById('staff-active-avatar').src = currentStaff.avatar;
    document.getElementById('staff-salon-name').innerText = state.salon.name;
  }

  // Tab İçerikleri
  const agendaContainer = document.getElementById('staff-agenda-container');
  const chatContainer = document.getElementById('staff-chat-container');
  const permInfoContainer = document.getElementById('staff-perms-container');

  if (!agendaContainer) return;

  if (activeStaffTab === "agenda") {
    agendaContainer.style.display = 'block';
    chatContainer.style.display = 'none';
    permInfoContainer.style.display = 'none';
    renderStaffAgenda(currentStaff);
  } else if (activeStaffTab === "chat") {
    agendaContainer.style.display = 'none';
    chatContainer.style.display = 'flex';
    permInfoContainer.style.display = 'none';
    renderStaffChat(currentStaff);
  } else if (activeStaffTab === "permissions") {
    agendaContainer.style.display = 'none';
    chatContainer.style.display = 'none';
    permInfoContainer.style.display = 'block';
    renderStaffPermissionsView(currentStaff);
  }
}

function renderStaffAgenda(staff) {
  const container = document.getElementById('staff-agenda-list');
  const staffAppts = state.appointments.filter(a => a.staffId === staff.id);

  if (staffAppts.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 40px 10px; color: #94a3b8;">
        <div style="font-size: 32px; margin-bottom: 8px;">📅</div>
        <p style="font-size: 13px;">Bugün için henüz onaylanmış bir randevunuz bulunmuyor.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = staffAppts.map(a => {
    const srvNames = a.services.map(s => s.name).join(' + ');
    const phoneDisplay = staff.permissions.canViewCustomerPhone 
      ? `<a href="tel:${a.customerPhone}" style="color: var(--primary); text-decoration: none; font-size: 11px;">📞 ${a.customerPhone}</a>`
      : `<span style="font-size: 10px; color: #94a3b8;">🔒 Telefon Yönetici Tarafından Gizlendi</span>`;

    const cancelBtn = staff.permissions.canCancelAppointments && a.status === 'ONAYLANDI'
      ? `<button onclick="cancelAppointmentByStaff('${a.id}')" style="background: #fee2e2; color: #ef4444; border: 1px solid #fca5a5; font-size: 11px; padding: 4px 8px; border-radius: 6px; cursor: pointer;">İptal Et</button>`
      : '';

    return `
      <div class="card" style="border-left: 4px solid ${a.status === 'ONAYLANDI' ? '#10b981' : '#ef4444'};">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;">
          <div>
            <span style="font-size: 14px; font-weight: 700; color: #0f172a;">⏰ ${a.startTime} - ${a.endTime}</span>
            <div style="font-size: 11px; color: #64748b;">Süre: ${a.totalDuration} dakika</div>
          </div>
          <span class="badge ${a.status === 'ONAYLANDI' ? 'badge-success' : 'badge-danger'}">${a.status}</span>
        </div>

        <div style="margin: 8px 0; padding: 8px; background: #f8fafc; border-radius: 6px;">
          <div style="font-size: 13px; font-weight: 600; color: #1e293b;">👤 ${a.customerName}</div>
          <div style="margin-top: 2px;">${phoneDisplay}</div>
          <div style="font-size: 12px; color: #475569; margin-top: 4px;">✂️ <b>Hizmetler:</b> ${srvNames}</div>
        </div>

        <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 8px;">
          <button onclick="openChatWithCustomer('${a.id}')" style="background: var(--primary); color: #fff; border: none; padding: 6px 12px; border-radius: 6px; font-size: 11px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 4px;">
            💬 Müşteriye Mesaj Yaz
          </button>
          ${cancelBtn}
        </div>
      </div>
    `;
  }).join('');
}

function renderStaffChat(staff) {
  const msgs = state.chats[activeChatAppointmentId] || [];
  const appt = state.appointments.find(a => a.id === activeChatAppointmentId);
  const titleElem = document.getElementById('staff-chat-customer-title');
  if (titleElem && appt) {
    titleElem.innerText = `${appt.customerName} ile Sohbet (Randevu: ${appt.startTime})`;
  }

  const container = document.getElementById('staff-chat-messages');
  if (container) {
    container.innerHTML = msgs.map(m => `
      <div class="msg-bubble ${m.sender === 'PERSONEL' ? 'outgoing' : 'incoming'}">
        <div>${m.text}</div>
        <div class="msg-time">${m.time}</div>
      </div>
    `).join('');
    container.scrollTop = container.scrollHeight;
  }
}

function renderStaffPermissionsView(staff) {
  const container = document.getElementById('staff-perms-info');
  const allowedSrv = state.services.filter(s => staff.allowedServices.includes(s.id));

  container.innerHTML = `
    <div class="card">
      <div class="card-title">🛡️ Yönetici Tarafından Verilen Yetkiler</div>
      <p style="font-size: 12px; color: #64748b; margin-bottom: 12px;">Yöneticiniz profilinize aşağıdaki yetkileri tanımlamıştır:</p>
      
      <div style="display: flex; flex-direction: column; gap: 8px; font-size: 12px;">
        <div style="display: flex; justify-content: space-between;">
          <span>📞 Müşteri Telefonunu Görme:</span>
          <b>${staff.permissions.canViewCustomerPhone ? '✅ İzin Verildi' : '❌ Gizlendi'}</b>
        </div>
        <div style="display: flex; justify-content: space-between;">
          <span>🚫 Randevu İptal Edebilme:</span>
          <b>${staff.permissions.canCancelAppointments ? '✅ İzin Verildi' : '❌ Kapalı'}</b>
        </div>
        <div style="display: flex; justify-content: space-between;">
          <span>☕ Mola & Saat Bloklama:</span>
          <b>${staff.permissions.canAddManualBreaks ? '✅ İzin Verildi' : '❌ Kapalı'}</b>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">✂️ Yapmaya Yetkili Olduğunuz Hizmetler</div>
      <p style="font-size: 11px; color: #64748b; margin-bottom: 8px;">Müşteriler sizden sadece aşağıdaki hizmetleri seçerek randevu alabilir:</p>
      <div style="display: flex; flex-wrap: wrap; gap: 6px;">
        ${allowedSrv.map(s => `
          <span style="background: var(--primary-light); color: var(--primary-hover); font-weight: 600; padding: 4px 8px; border-radius: 6px; font-size: 11px;">
            ✓ ${s.name} (${s.durationMinutes} dk)
          </span>
        `).join('')}
      </div>
    </div>
  `;
}

function sendStaffMessage() {
  const input = document.getElementById('staff-chat-input');
  const text = input.value.trim();
  if (!text) return;

  if (!state.chats[activeChatAppointmentId]) {
    state.chats[activeChatAppointmentId] = [];
  }

  const now = new Date();
  const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

  state.chats[activeChatAppointmentId].push({
    sender: 'PERSONEL',
    text: text,
    time: timeStr
  });

  saveState();
  input.value = '';
  renderStaffView();
  renderCustomerView();
  showToast("Müşteriye mesajınız iletildi!");
}

function sendQuickStaffMessage(text) {
  document.getElementById('staff-chat-input').value = text;
  sendStaffMessage();
}

function openChatWithCustomer(appointmentId) {
  activeChatAppointmentId = appointmentId;
  activeStaffTab = "chat";
  activeCustomerTab = "chat";
  renderAllViews();
}

function cancelAppointmentByStaff(id) {
  const appt = state.appointments.find(a => a.id === id);
  if (!appt) return;

  if (confirm("Bu randevuyu iptal etmek istediğinizden emin misiniz?")) {
    appt.status = "IPTAL";
    saveState();
    showToast("Randevu personel tarafından iptal edildi.");
    renderAllViews();
  }
}

// ==========================================
// 3. MÜŞTERİ PANELİ (MOBİL)
// ==========================================
function renderCustomerView() {
  // Salon bilgileri
  const salonNameElem = document.getElementById('cust-salon-name');
  if (salonNameElem) {
    salonNameElem.innerText = state.salon.name;
    document.getElementById('cust-salon-address').innerText = state.salon.address;
    document.getElementById('cust-salon-phone').innerText = state.salon.phone;
  }

  // Tab kontrolleri
  const bookingContainer = document.getElementById('cust-booking-container');
  const myApptsContainer = document.getElementById('cust-my-appts-container');
  const chatContainer = document.getElementById('cust-chat-container');

  if (!bookingContainer) return;

  if (activeCustomerTab === "booking") {
    bookingContainer.style.display = 'block';
    myApptsContainer.style.display = 'none';
    chatContainer.style.display = 'none';
    renderCustomerBooking();
  } else if (activeCustomerTab === "my-appointments") {
    bookingContainer.style.display = 'none';
    myApptsContainer.style.display = 'block';
    chatContainer.style.display = 'none';
    renderCustomerMyAppointments();
  } else if (activeCustomerTab === "chat") {
    bookingContainer.style.display = 'none';
    myApptsContainer.style.display = 'none';
    chatContainer.style.display = 'flex';
    renderCustomerChat();
  }
}

function renderCustomerBooking() {
  // Kuaför Seçimi Kartları
  const staffGrid = document.getElementById('cust-staff-selection');
  if (staffGrid) {
    staffGrid.innerHTML = state.staff.map(st => `
      <div class="staff-select-card ${st.id === selectedStaffId ? 'selected' : ''}" onclick="selectStaffForCustomer(${st.id})">
        <img src="${st.avatar}" class="staff-avatar-img">
        <div class="staff-card-name">${st.name}</div>
        <div class="staff-card-title">${st.title}</div>
      </div>
    `).join('');
  }

  // Seçilen personele göre yapabileceği hizmetleri filtrele
  const currentStaff = state.staff.find(s => s.id === selectedStaffId) || state.staff[0];
  const staffAllowedServices = state.services.filter(s => currentStaff.allowedServices.includes(s.id));

  // Eğer mevcut seçili hizmetler personelin yapamadığı bir hizmetse temizle
  selectedServiceIds = selectedServiceIds.filter(id => currentStaff.allowedServices.includes(id));
  if (selectedServiceIds.length === 0 && staffAllowedServices.length > 0) {
    selectedServiceIds = [staffAllowedServices[0].id];
  }

  // Hizmet Listesi
  const srvList = document.getElementById('cust-service-selection');
  if (srvList) {
    srvList.innerHTML = staffAllowedServices.map(srv => {
      const isSelected = selectedServiceIds.includes(srv.id);
      return `
        <div class="service-select-item ${isSelected ? 'selected' : ''}" onclick="toggleCustomerService(${srv.id})">
          <div>
            <div class="service-name">${srv.name}</div>
            <div class="service-meta">
              <span>⏳ ${srv.durationMinutes} dakika</span>
              <span>•</span>
              <span>${srv.category}</span>
            </div>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <div class="service-price">${srv.price} ₺</div>
            <span style="font-size: 16px;">${isSelected ? '✅' : '⚪'}</span>
          </div>
        </div>
      `;
    }).join('');
  }

  // Toplam Süre & Fiyat Özeti
  const selectedServices = state.services.filter(s => selectedServiceIds.includes(s.id));
  const totalDuration = selectedServices.reduce((sum, s) => sum + s.durationMinutes, 0);
  const totalPrice = selectedServices.reduce((sum, s) => sum + s.price, 0);

  const durationElem = document.getElementById('cust-total-duration');
  if (durationElem) {
    durationElem.innerText = `${totalDuration} dakika`;
    document.getElementById('cust-total-price').innerText = `${totalPrice} ₺`;
  }

  // Tarih seçici
  const dateInput = document.getElementById('cust-date-picker');
  if (dateInput) {
    dateInput.value = selectedDate;
  }

  // Dinamik Slotları Hesapla ve Çiz
  renderDynamicSlots(currentStaff, totalDuration);
}

function selectStaffForCustomer(staffId) {
  selectedStaffId = staffId;
  selectedSlot = null;
  renderCustomerView();
}

function toggleCustomerService(serviceId) {
  const idx = selectedServiceIds.indexOf(serviceId);
  if (idx > -1) {
    if (selectedServiceIds.length > 1) {
      selectedServiceIds.splice(idx, 1);
    } else {
      showToast("En az bir hizmet seçilmelidir.");
      return;
    }
  } else {
    selectedServiceIds.push(serviceId);
  }
  selectedSlot = null;
  renderCustomerView();
}

function onCustomerDateChange(newDate) {
  selectedDate = newDate;
  selectedSlot = null;
  renderCustomerView();
}

// ==========================================
// DİNAMİK SLOT HESAPLAMA MOTORU (ALGORİTMA)
// ==========================================
function renderDynamicSlots(staff, totalDuration) {
  const container = document.getElementById('cust-slots-container');
  if (!container) return;

  if (totalDuration <= 0) {
    container.innerHTML = `<div style="grid-column: span 3; font-size: 11px; color: #94a3b8; text-align: center;">Lütfen en az bir hizmet seçin.</div>`;
    return;
  }

  // Çalışma saatlerini dakikaya çevir (09:00 -> 540 dk)
  const [openH, openM] = state.salon.openTime.split(':').map(Number);
  const [closeH, closeM] = state.salon.closeTime.split(':').map(Number);
  const startMinute = openH * 60 + openM;
  const endMinute = closeH * 60 + closeM;

  // Öğle molası
  const [lunchStartH, lunchStartM] = state.salon.lunchStart.split(':').map(Number);
  const [lunchEndH, lunchEndM] = state.salon.lunchEnd.split(':').map(Number);
  const lunchStartMin = lunchStartH * 60 + lunchStartM;
  const lunchEndMin = lunchEndH * 60 + lunchEndM;

  // Seçili tarihteki mevcut onaylı randevuları al
  const existingAppts = state.appointments.filter(a => 
    a.staffId === staff.id && 
    a.date === selectedDate && 
    a.status === 'ONAYLANDI'
  );

  const busyIntervals = existingAppts.map(a => {
    const [sH, sM] = a.startTime.split(':').map(Number);
    const [eH, eM] = a.endTime.split(':').map(Number);
    return { start: sH * 60 + sM, end: eH * 60 + eM };
  });

  // Öğle molasını da meşgul aralık olarak ekle
  busyIntervals.push({ start: lunchStartMin, end: lunchEndMin });

  const slotButtons = [];
  const step = 15; // 15 dakikalık adımlarla boşluk ara

  for (let m = startMinute; m + totalDuration <= endMinute; m += step) {
    const slotStart = m;
    const slotEnd = m + totalDuration;

    // Bu slot aralığında herhangi bir çakışma var mı?
    const hasOverlap = busyIntervals.some(inv => {
      return (slotStart < inv.end && slotEnd > inv.start);
    });

    const timeLabel = formatMinutesToTime(slotStart);
    const isSelected = selectedSlot === timeLabel;

    if (!hasOverlap) {
      slotButtons.push(`
        <button class="slot-btn ${isSelected ? 'selected' : ''}" onclick="selectTimeSlot('${timeLabel}')">
          ${timeLabel}
        </button>
      `);
    } else {
      slotButtons.push(`
        <button class="slot-btn disabled" title="Dolu veya Mola" disabled>
          ${timeLabel}
        </button>
      `);
    }
  }

  if (slotButtons.length === 0) {
    container.innerHTML = `<div style="grid-column: span 3; font-size: 11px; color: #ef4444; text-align: center;">Bu tarihte ${totalDuration} dakikalık uygun boşluk kalmamıştır.</div>`;
  } else {
    container.innerHTML = slotButtons.join('');
  }
}

function formatMinutesToTime(mins) {
  const h = Math.floor(mins / 60).toString().padStart(2, '0');
  const m = (mins % 60).toString().padStart(2, '0');
  return `${h}:${m}`;
}

function selectTimeSlot(timeStr) {
  selectedSlot = timeStr;
  renderCustomerView();
}

function confirmCustomerAppointment() {
  if (!selectedSlot) {
    alert("Lütfen randevu için bir saat dilimi seçin.");
    return;
  }

  const nameInput = document.getElementById('cust-input-name');
  const phoneInput = document.getElementById('cust-input-phone');
  const customerName = nameInput ? nameInput.value.trim() : "Müşteri";
  const customerPhone = phoneInput ? phoneInput.value.trim() : "0500 000 00 00";

  const staff = state.staff.find(s => s.id === selectedStaffId);
  const selectedServices = state.services.filter(s => selectedServiceIds.includes(s.id));
  const totalDuration = selectedServices.reduce((sum, s) => sum + s.durationMinutes, 0);
  const totalPrice = selectedServices.reduce((sum, s) => sum + s.price, 0);

  // Bitiş saatini hesapla
  const [sH, sM] = selectedSlot.split(':').map(Number);
  const endMinutes = sH * 60 + sM + totalDuration;
  const endTime = formatMinutesToTime(endMinutes);

  const newApptId = "APT-" + Math.floor(100 + Math.random() * 900);

  const newAppt = {
    id: newApptId,
    salonId: 1,
    staffId: staff.id,
    customerName: customerName,
    customerPhone: customerPhone,
    services: selectedServices,
    totalDuration: totalDuration,
    totalPrice: totalPrice,
    date: selectedDate,
    startTime: selectedSlot,
    endTime: endTime,
    status: "ONAYLANDI",
    createdAt: new Date().toISOString()
  };

  state.appointments.push(newAppt);

  // Otomatik hoşgeldiniz mesajı başlat
  state.chats[newApptId] = [
    { sender: "PERSONEL", text: `Merhaba ${customerName}, randevunuzu aldım (${selectedSlot}). Görüşmek üzere!`, time: selectedSlot }
  ];

  activeChatAppointmentId = newApptId;
  saveState();

  showToast(`🎉 Randevunuz başarıyla oluşturuldu! (${staff.name} - ${selectedSlot})`);
  selectedSlot = null;
  activeCustomerTab = "my-appointments";
  renderAllViews();
}

// ==========================================
// 3 SAAT İPTAL KURALI VE RANDEVULARIM
// ==========================================
function renderCustomerMyAppointments() {
  const container = document.getElementById('cust-my-appts-list');
  if (!container) return;

  if (state.appointments.length === 0) {
    container.innerHTML = `<div style="text-align: center; padding: 40px; color: #94a3b8;">Henüz bir randevunuz bulunmamaktadır.</div>`;
    return;
  }

  // Simüle edilen "Şu Anki Zaman": Gerçek zaman + virtualClockOffsetHours
  const simulatedNow = new Date(Date.now() + state.timeTravelOffsetHours * 60 * 60 * 1000);

  container.innerHTML = state.appointments.map(appt => {
    const staff = state.staff.find(s => s.id === appt.staffId) || { name: 'Kuaför' };
    const srvNames = appt.services.map(s => s.name).join(' + ');

    // Randevu DateTime nesnesini oluştur
    const [startH, startM] = appt.startTime.split(':').map(Number);
    const apptDateTime = new Date(`${appt.date}T${startH.toString().padStart(2, '0')}:${startM.toString().padStart(2, '0')}:00`);

    // Randevuya kalan saat farkı
    const diffMs = apptDateTime.getTime() - simulatedNow.getTime();
    const remainingHours = diffMs / (1000 * 60 * 60);

    const isCancelled = appt.status === 'IPTAL';
    const isPast = diffMs < 0;
    
    // 3 Saat İptal Kuralı Kontrolü
    const canCancel = !isCancelled && !isPast && remainingHours >= 3.0;

    let timeBadgeText = "";
    if (isCancelled) {
      timeBadgeText = "İPTAL EDİLDİ";
    } else if (isPast) {
      timeBadgeText = "TAMAMLANDI";
    } else {
      const h = Math.floor(remainingHours);
      const m = Math.floor((remainingHours - h) * 60);
      timeBadgeText = `Randevuya ${h} saat ${m} dk kaldı`;
    }

    return `
      <div class="card" style="border-left: 4px solid ${isCancelled ? '#ef4444' : (canCancel ? '#10b981' : '#f59e0b')};">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;">
          <div>
            <span style="font-size: 14px; font-weight: 700;">📅 ${appt.date} | ⏰ ${appt.startTime} - ${appt.endTime}</span>
            <div style="font-size: 11px; color: #64748b;">Kuaför: <b>${staff.name}</b></div>
          </div>
          <span class="badge ${isCancelled ? 'badge-danger' : (canCancel ? 'badge-success' : 'badge-warning')}">
            ${isCancelled ? 'İPTAL' : (canCancel ? 'Aktif' : 'Son 3 Saat')}
          </span>
        </div>

        <div style="font-size: 12px; color: #334155; margin: 6px 0;">
          ✂️ <b>Hizmet:</b> ${srvNames} (${appt.totalDuration} dk)
          <br>💰 <b>Tutar:</b> ${appt.totalPrice} ₺
        </div>

        <div style="background: #f1f5f9; padding: 6px 10px; border-radius: 6px; font-size: 11px; margin: 8px 0; display: flex; justify-content: space-between; align-items: center;">
          <span>⏳ <b>Durum:</b> ${timeBadgeText}</span>
          ${canCancel 
            ? '<span style="color: #059669; font-weight: 700;">✓ İptal Edilebilir</span>' 
            : (!isCancelled ? '<span style="color: #d97706; font-weight: 700;">⚠️ İptal Kilitli</span>' : '')}
        </div>

        ${!canCancel && !isCancelled && !isPast ? `
          <div style="font-size: 10px; color: #b45309; background: #fffbeb; border: 1px solid #fde68a; padding: 6px; border-radius: 6px; margin-bottom: 8px;">
            ⚠️ <b>3 Saat İptal Kuralı:</b> Randevunuza 3 saatten az kaldığı için uygulama üzerinden iptal yapılamaz. İptal talebi için lütfen kuaförü doğrudan arayınız.
          </div>
        ` : ''}

        <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 6px;">
          <button onclick="openChatWithCustomer('${appt.id}')" style="background: var(--primary); color: #fff; border: none; padding: 6px 12px; border-radius: 6px; font-size: 11px; font-weight: 600; cursor: pointer;">
            💬 Kuaförle Yazış
          </button>

          ${!isCancelled ? `
            <button class="btn-cancel-appt" ${canCancel ? '' : 'disabled'} onclick="cancelAppointmentByCustomer('${appt.id}')">
              ❌ Randevuyu İptal Et
            </button>
          ` : '<span style="font-size: 11px; color: #ef4444; font-weight: 600;">İptal Edildi</span>'}
        </div>
      </div>
    `;
  }).join('');
}

function cancelAppointmentByCustomer(id) {
  const appt = state.appointments.find(a => a.id === id);
  if (!appt) return;

  if (confirm("Randevunuzu iptal etmek istediğinizden emin misiniz?")) {
    appt.status = "IPTAL";
    saveState();
    showToast("Randevunuz iptal edildi. Slot takvimde tekrar boşa çıkarıldı.");
    renderAllViews();
  }
}

function renderCustomerChat() {
  const msgs = state.chats[activeChatAppointmentId] || [];
  const appt = state.appointments.find(a => a.id === activeChatAppointmentId);
  const staff = appt ? state.staff.find(s => s.id === appt.staffId) : state.staff[0];

  const titleElem = document.getElementById('cust-chat-staff-title');
  if (titleElem && staff) {
    titleElem.innerText = `${staff.name} ile Sohbet`;
  }

  const container = document.getElementById('cust-chat-messages');
  if (container) {
    container.innerHTML = msgs.map(m => `
      <div class="msg-bubble ${m.sender === 'MUSTERI' ? 'outgoing' : 'incoming'}">
        <div>${m.text}</div>
        <div class="msg-time">${m.time}</div>
      </div>
    `).join('');
    container.scrollTop = container.scrollHeight;
  }
}

function sendCustomerMessage() {
  const input = document.getElementById('cust-chat-input');
  const text = input.value.trim();
  if (!text) return;

  if (!state.chats[activeChatAppointmentId]) {
    state.chats[activeChatAppointmentId] = [];
  }

  const now = new Date();
  const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

  state.chats[activeChatAppointmentId].push({
    sender: 'MUSTERI',
    text: text,
    time: timeStr
  });

  saveState();
  input.value = '';
  renderStaffView();
  renderCustomerView();
  showToast("Mesajınız kuaföre iletildi!");
}

function sendQuickCustomerMessage(text) {
  document.getElementById('cust-chat-input').value = text;
  sendCustomerMessage();
}

// Zaman Yolculuğu Test Kontrolleri
function setTimeTravelOffset(hours) {
  state.timeTravelOffsetHours = hours;
  const label = hours === 0 ? "Gerçek Zamanlı" : (hours > 0 ? `+${hours} Saat İleride` : `${hours} Saat Geride`);
  showToast(`⏰ Simülasyon Saati Değiştirildi: ${label}`);
  renderCustomerMyAppointments();
}

// Toast Bildirim
function showToast(msg) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `<span>🔔</span> <span>${msg}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.remove();
  }, 3500);
}
