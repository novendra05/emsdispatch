$(function() {
    const historyModal = $('#history-modal');
    const historyList = $('#call-history-list');
    const notificationContainer = $('#notification-container');

    window.addEventListener('message', function(event) {
        const item = event.data;

        if (item.type === 'open_history') {
            console.log("[MDT-Dispatch] Received History:", item.history);
            renderHistory(item.history);
            historyModal.removeClass('hidden');
        }

        if (item.type === 'new_call') {
            console.log("[MDT-Dispatch] Received New Call Notification:", item.payload);
            showNotification(item.payload);
        }
    });

    function renderHistory(history) {
        historyList.empty();

        if (!history || history.length === 0) {
            historyList.append(`
                <div style="text-align: center; padding: 100px; opacity: 0.3;">
                    <i class="fas fa-inbox text-5xl mb-4"></i>
                    <p class="font-bold uppercase tracking-widest text-sm">No Active Signals (5m Window)</p>
                </div>
            `);
            return;
        }

        history.forEach(call => {
            const hasResponder = call.responder && call.responder !== "";
            const card = $(`
                <div class="call-card ${hasResponder ? 'responded' : 'pending'}">
                    <div class="call-icon">
                        <i class="fas ${hasResponder ? 'fa-check-circle text-emerald-500' : 'fa-phone-volume'}"></i>
                    </div>
                    <div class="call-info">
                        <div class="call-meta">
                            <span class="call-time">${call.time}</span>
                            <span class="call-caller">${call.name} [ID: ${call.id}]</span>
                            ${hasResponder ? `<span class="responder-tag"><i class="fas fa-user-md"></i> ${call.responder}</span>` : ''}
                        </div>
                        <div class="call-msg" style="margin-bottom: 8px; font-style: italic;">"${call.message}"</div>
                        <div style="font-size: 11px; font-weight: 700; color: var(--text-muted);">
                            <i class="fas fa-map-marker-alt text-blue-500 mr-1"></i> ${call.street || 'Unknown Street'}
                        </div>
                    </div>
                    <div class="call-actions">
                        <button class="btn-gps" onclick="setGPS(${call.coords.x}, ${call.coords.y}, ${call.id})">
                            <i class="fas fa-location-arrow"></i> ${hasResponder ? 'MARK GPS' : 'RESPOND'}
                        </button>
                    </div>
                </div>
            `);
            historyList.append(card);
        });
    }

    window.setGPS = function(x, y, callId = null) {
        $.post(`https://ems-dispatch/setGPS`, JSON.stringify({ x, y, callId }));
    };

    let callIndex = 0;
    function showNotification(data) {
        callIndex++;
        const id = Date.now();
        const notification = $(`
            <div class="dispatch-alert" id="notif-${id}">
                <div class="alert-top">
                    <span class="id-label">#${callIndex}</span>
                    <span class="badge-311">311</span>
                    <span class="alert-title">311 CALL: ${data.message}</span>
                    <i class="fas fa-tower-broadcast signal-icon"></i>
                </div>
                
                <div class="alert-info-row">
                    <span class="info-label">LOC</span>
                    <span class="info-value">${data.street}</span>
                </div>

                <div class="alert-info-row">
                    <span class="info-label">CALLER</span>
                    <span class="info-value">${data.name}</span>
                </div>

                <div class="alert-footer">
                    <span class="instruction-label">INSTRUCTION</span>
                    <div class="gps-badge" onclick="setGPS(${data.coords.x}, ${data.coords.y}, ${data.id})">
                        [E] MARK GPS
                    </div>
                </div>
            </div>
        `);

        notificationContainer.prepend(notification);
        setTimeout(() => notification.addClass('active'), 100);

        // Remove after 10 seconds
        setTimeout(() => {
            notification.removeClass('active');
            setTimeout(() => notification.remove(), 500);
        }, 10000);
    }

    $('#close-history').on('click', function() {
        historyModal.addClass('hidden');
        $.post(`https://ems-dispatch/closeUI`, JSON.stringify({}));
    });

    document.onkeydown = function(data) {
        if (data.key === "Escape") {
            historyModal.addClass('hidden');
            $.post(`https://ems-dispatch/closeUI`, JSON.stringify({}));
        }
    };
});
