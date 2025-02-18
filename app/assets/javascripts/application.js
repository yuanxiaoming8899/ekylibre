// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require webpack_bridge
//= require modernizr
//= require jquery
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/i18n/datepicker-fr
// require jquery-ui/i18n/datepicker-ar
// require jquery-ui/i18n/datepicker-ja
//= require jquery-ui/widgets/dialog
//= require jquery-ui/widgets/slider
//= require jquery-ui/widgets/accordion
//= require jquery-ui/widgets/sortable
//= require jquery-ui/widgets/droppable
//= require jquery_ujs
//= require jquery.remotipart
//= require jquery_turbolinks_patch
//= require turbolinks
//= require active_list.jquery
//= require knockout
//= require behave_compat
//= require_self
//= require wice_grid
//= require wice_grid/settings
//= require ekylibre
//= require form/dialog
//= require formize/observe
//= require form/scope
//= require form/dependents
//= require form/toggle
//= require form/dates
//= require form/links
//= require cocoon
//= require jquery/ext
//= require selector
//= require ui
//= require jstz
//= require heatmap
//= require geographiclib
//= require leaflet-reactive_measure/dist/reactive_measure.js
//= require leaflet/fullscreen
//= require leaflet/providers
//= require leaflet/heatmap
//= require leaflet/measure
//= require leaflet/easy-button
//= require leaflet/modal
//= require map_draw_i18n
//= require eky-cartography.js
//= require cartography/map
//= require plugins
//= require_tree .
//= require tour
//= require bootstrap-slider
//= require leaflet/L.KML
//= require chart/highcharts

//= require sortablejs/Sortable.min.js

//= require turbolinks_patch

//= require channels

// FIX Browser interoperability
// href function seems to be ineffective
$.rails.href = function (element) {
    return $(element).attr('href');
};

$(document).ready(function() {
  L.Icon.Default.imagePath = '/assets';
  $(".snippet-content > ul > li").click(function(e) {
    localStorage.scrollTop = $('.inner').scrollTop();
  });
  $('.inner').animate({ scrollTop: localStorage.scrollTop }, 0);
  $(".collapse").click(function(){
    localStorage.clear();
  });
});
