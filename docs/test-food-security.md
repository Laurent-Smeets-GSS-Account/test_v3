# Regional Food Insecurity building

<script src="Food_insecuity_files/libs/kePrint-0.0.1/kePrint.js"></script>
<link href="Food_insecuity_files/libs/lightable-0.0.1/lightable.css" rel="stylesheet" />


## Summary of Food Inscurity

### Fies Indicators over time

This chart displays the levels of food insecurity in Indonesia from
March 2024 to January 2025, highlighting a general downward trend across
all FIES (Food Insecurity Experience Scale) indicators, with milder
concerns like “worried about not having enough food” (29.8%) remaining
most prevalent, while severe experiences such as “went without eating
for a whole day” (2.3%) affected the smallest portion of the population.

<div class="flourish-embed flourish-chart"
data-src="visualisation/21862009?2455648" data-height="1000px">

<script src="https://public.flourish.studio/resources/embed.js"></script>
<noscript>
<img src="https://public.flourish.studio/visualisation/21862009/thumbnail" width="100%" height="1000px" alt="chart visualization" />
</noscript>

</div>


### Distribution of number of FIES deprivations

Indonesia’s FIES deprivation data reveals 63.4% of the population
experiences zero food insecurity indicators, with percentages steadily
declining as severity increases—12.9% face one deprivation, 5.7% face
two, and only 1.8% of Indonesians experience all eight FIES
deprivations, demonstrating that food insecurity follows a clear
gradient with most citizens experiencing either none or few food
challenges.
<div class="custom-tabs">
  <div class="custom-tabs-nav">
    <button class="custom-tab-btn active" onclick="showTab(this, 'tab1')">Step chart</button>
    <button class="custom-tab-btn" onclick="showTab(this, 'tab2')">Area chart by count</button>
  </div>

  <div id="tab1" class="custom-tab-content active">
    <div class="flourish-embed flourish-chart" data-src="visualisation/21864340?2455648" data-height="800px">
      <script src="https://public.flourish.studio/resources/embed.js"></script>
      <noscript>
        <img src="https://public.flourish.studio/visualisation/21864340/thumbnail" width="100%" height="800px" alt="chart visualization" />
      </noscript>
    </div>
  </div>

  <div id="tab2" class="custom-tab-content">
    <div class="flourish-embed flourish-chart" data-src="visualisation/21865104?2455648" data-height="800px">
      <script src="https://public.flourish.studio/resources/embed.js"></script>
      <noscript>
        <img src="https://public.flourish.studio/visualisation/21865104/thumbnail" width="100%" height="800px" alt="chart visualization" />
      </noscript>
    </div>
  </div>
</div>

<style>
.custom-tabs {
  margin: 20px 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}
.custom-tabs-nav {
  display: flex;
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 15px;
}
.custom-tab-btn {
  padding: 8px 16px;
  background: none;
  border: 1px solid transparent;
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
  cursor: pointer;
  margin-bottom: -1px;
  font-size: 16px;
  color: #495057;
}
.custom-tab-btn:hover {
  border-color: #e9ecef #e9ecef #dee2e6;
  color: #0d6efd;
}
.custom-tab-btn.active {
  color: #0d6efd;
  background-color: #fff;
  border-color: #dee2e6 #dee2e6 #fff;
  font-weight: 500;
}
.custom-tab-content {
  display: none;
}
.custom-tab-content.active {
  display: block;
}
</style>

<script>
function showTab(button, tabId) {
  // Hide all tab contents
  var contents = document.getElementsByClassName('custom-tab-content');
  for (var i = 0; i < contents.length; i++) {
    contents[i].classList.remove('active');
  }
  
  // Deactivate all buttons
  var buttons = document.getElementsByClassName('custom-tab-btn');
  for (var i = 0; i < buttons.length; i++) {
    buttons[i].classList.remove('active');
  }
  
  // Activate the clicked button and show the corresponding tab
  button.classList.add('active');
  document.getElementById(tabId).classList.add('active');
}
</script>