//= require active_admin/base
//= require activeadmin_addons/all

// TRM auto-calculation for Plan COP <-> USD
document.addEventListener('DOMContentLoaded', function() {
  // Run on page load and on Turbo/Turbolinks navigations
  function initPlanTRM() {
    var copField = document.querySelector('input[name="plan[price_monthly]"]');
    var usdField = document.querySelector('input[name="plan[price_monthly_usd]"]');
    var trmHint = document.querySelector('.plan_price_monthly .inline-hints');

    if (!copField || !usdField || copField.dataset.trmBound) return;
    copField.dataset.trmBound = '1';

    // Extract TRM from hint text: "TRM actual: $3,667 COP/USD"
    var trm = 3667;
    if (trmHint) {
      var match = trmHint.textContent.match(/\$([\d,.]+)/);
      if (match) trm = parseFloat(match[1].replace(/[.,]/g, '')) || 3667;
    }

    copField.addEventListener('input', function() {
      var cop = parseFloat(this.value) || 0;
      usdField.value = cop > 0 ? Math.round(cop / trm) : '';
    });
    usdField.addEventListener('input', function() {
      var usd = parseFloat(this.value) || 0;
      copField.value = usd > 0 ? Math.round(usd * trm) : '';
    });
  }

  initPlanTRM();
  // For Turbolinks/Turbo re-navigations
  document.addEventListener('turbolinks:load', initPlanTRM);
  document.addEventListener('turbo:load', initPlanTRM);
});

// Features dynamic add/remove for Plan form
document.addEventListener('DOMContentLoaded', function() {
  function initFeatures() {
    var container = document.getElementById('features-container');
    var addBtn = document.getElementById('add-feature-btn');
    if (!container || !addBtn || addBtn.dataset.bound) return;
    addBtn.dataset.bound = '1';

    addBtn.addEventListener('click', function() {
      var row = document.createElement('div');
      row.className = 'feature-row';
      row.style = 'display:flex;gap:8px;margin-bottom:8px;align-items:center;';
      row.innerHTML = '<input type="text" name="plan[features][]" value="" style="flex:1;padding:6px 10px;border:1px solid #ccc;border-radius:4px;" placeholder="Ej: Agenda y calendario" />' +
        '<button type="button" class="remove-feature" style="background:#ef4444;color:white;border:none;border-radius:4px;padding:4px 10px;cursor:pointer;">✕</button>';
      container.appendChild(row);
      row.querySelector('input').focus();
    });
    container.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-feature')) {
        e.target.parentElement.remove();
      }
    });
  }

  initFeatures();
  document.addEventListener('turbolinks:load', initFeatures);
  document.addEventListener('turbo:load', initFeatures);
});
