
var _api = '/api/v1';
var _re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
var _images = {};
var _colours = ['green', 'yellow', 'blue', 'red', 'cyan', 'DarkGray', 'DarkMagenta', 'HotPink', 'LawnGreen'];
var _npolygons = 0;
var _polygons = {};

var _login_modal = new bootstrap.Modal(document.getElementById('login'), { keyboard: true });
var _signup_modal = new bootstrap.Modal(document.getElementById('signup'), { keyboard: true });
var _signup_success_modal = new bootstrap.Modal(document.getElementById('signup_success'), { keyboard: true });
var _gallery_modal = new bootstrap.Modal(document.getElementById('gallery'), { keyboard: true });
var _processing_modal = new bootstrap.Modal(document.getElementById('processing_modal'), { keyboard: true });
var _gallery_carousel = null;

var _nshow_more = 1
var _current_image = 1;


const icon = {
  url: "https://questagame.s3.ap-southeast-2.amazonaws.com/maps-icon.png", // url
  scaledSize: new google.maps.Size(31, 40), // scaled size
  origin: new google.maps.Point(0, 0), // origin
  anchor: new google.maps.Point(15, 40), // anchor
};

const dashed_line_symbol = {
  path: "M 0,-1 0,1",
  strokeOpacity: 1,
  scale: 6,
};
const line_symbol = {
  path: "M 0, 1 0,1",
  strokeOpacity: 1,
  scale: 4,
};
var make_select_auto_complete = false;
var empty_list = true;

$(document).ready(function() { 
  set_up_authentication();
  set_up_top_page();
  set_up_regions();
  set_up_contests();
  set_up_participations();
  set_up_region_page();
  set_up_contest_page();
  set_up_observations();
  set_up_counters();
  autocomplete_species();
});

function reload(atag='') {
  var url = new URL(location.href+(atag.length>0 && location.href.indexOf(atag)==-1 ? '#'+atag : ''));
  window.location = url.href;
  location.reload();
}

function require_valid_text(target) {
  target = $(target);
  // Return Focus
  target.focus();
  // Add alert class
  target.addClass("ui-state-alert");

  if ($(".required-alert-text").length == 0) {
    $("<div>", {
      class: "required-alert-text row justify-content-center mt-3",
      style: "color: #F00; font-size: 18px;"
    }).html("Please type and select from the list of suggestions").insertAfter($(".search-species" ));
  }
  $(':submit').attr('disabled', 'disabled');
}

function autocomplete_species() {
  var data_src;
  api_url = _api + '/observations/species/autocomplete';

  // $.ajax({
  //   async: false,
  //   url: api_url,
  //   type: 'get',
  //   contentType: "application/json",
  //   success: function(data) {
  //     data_src = JSON.parse(data.data);
  //   }
  // });

  $('#search_by_species').autocomplete({
    // source: data_src,
    // source: $('#search_by_species').data('autocomplete-source'),
    delay: 500,
    source: function(request, response) {
      $.ajax({
          url: api_url,
          type: 'get',
          contentType: "application/json",
          jsonpCallback: 'jsonCallback',
          data: {
            term: request.term,
          },
          success: function(data) {
             resp_data = JSON.parse(data.data);
             if (resp_data.length <= 0) {
              empty_list = true;
             }
             else {
              empty_list = false;
             }
             response(JSON.parse(data.data));
          }
      });
    },
    select: function(e, ui) {
      make_select_auto_complete = true;
    },
    close: function(e, ui) {
      if (make_select_auto_complete) {
        make_select_auto_complete = false;
        $(".ui-state-alert").removeClass("ui-state-alert");
        $(".required-alert-text").remove();
        $(':submit').removeAttr("disabled");
      } else {
        require_valid_text(this);
      }
    },
    response: function(e, ui) {
      if (empty_list) {
        require_valid_text(this);
      }
    },
    minLength: 3
  });
} 

function set_up_counters() {
  $('.countdown').each(function() {
    var starts_at = $(this).attr('data-starts-at');
    var id = $(this).attr('data-id');

    var x = setInterval(function() {
      var countDownDate = new Date(starts_at).getTime();
      var now = new Date().getTime();
      var distance = countDownDate - now;
      var days = Math.floor(distance / (1000 * 60 * 60 * 24));
      var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);

      var str = "";
      if(days!=0) str += days + " days ";
      if(days!=0 || hours!=0 ) str += hours + " hours ";
      if( (days!=0 && hours!=0 ) || minutes!=0) str += minutes + " minutes ";
      if( (days!=0 && hours!=0 && minutes!=0) || seconds!=0) str += seconds + " seconds";

      document.getElementById("countdown-"+id).innerHTML = str;
      if (distance<0) { 
        clearInterval(x); 
        document.getElementById("countdown-"+id).innerHTML = ""; 
      } 
    }, 1000);
  });
}

function clear_search_cookie(cookie_name) {
  var stored_pathname = Cookies.get("pathname");
  Cookies.remove(stored_pathname);
  Cookies.remove("q");
  if (cookie_name != 'q') Cookies.remove("category") ;
}

function set_up_observations() {

  var pathname = window.location.pathname;
  var stored_pathname = Cookies.get("pathname");
  if (pathname !== stored_pathname) {
    clear_search_cookie();
  }

  $(document).on('click', '.gallery-link', function() { 
    var link = $(this);    
    $('#gallery-carousel').html('');
    var urls = JSON.parse( link.attr('data-image-urls') );
    if(urls.length>0) {
      for( var i=0 ; i<urls.length ; i++ ) {
        var html = '<div class="carousel-item"><div class="card border-0 p-0 m-0">';
        html += '<img src="'+urls[i]+'" class="img-fluid" loading="lazy" alt="...">';
        html += '</div></div>';
        $('#gallery-carousel').append(html);
      } 

      $('.carousel-item').first().addClass('active');
      _gallery_modal.show();      
    }
  });

  $('#show_more').click(function() {
    var n = $('.observation').length;
    var params = $(this).attr('data-api-parameters');
    params += "&nstart="+n;
    params += "&nend="+(n + parseInt($(this).attr('data-n-per-fetch')));

    if(n>0 || location.href.indexOf('recent_observations')!=-1) _processing_modal.show();

    $.ajax({ url: ('/observations/more'+params), dataType: 'html' })
    .done(function(data, status) { $('#observations-block').append(data); })
    .fail(function(xhr, status, error) {})
    .always(function() { _processing_modal.hide(); });

    return false;
  });

  $('#show_more_contests').click(function() {
    var n = $('.contest').length;
    var params = "offset="+n;
    params += "&limit="+ parseInt($(this).attr('data-n-per-fetch'));

    $.ajax({ url: ('/contests/more?'+params), dataType: 'html' })
    .done(function(data, status) { $('#contests-block').append(data); })
    .fail(function(xhr, status, error) {});

    return false;
  });

  $('#search_clear').click(function() {
    var cookie_name = 'q'
    clear_search_cookie(cookie_name);
    $('#search_input').val(''); $('#search_button').click(); 
  });

  $("#search_button").click(function () {
    var q = $("#search_input").val().trim();
    if (q) {
      Cookies.set("pathname", pathname);
      Cookies.set("q", q);
    }

    reload("recent_observations");
  });


  $("#category_filter").change(function () {
    var filter = $("#category_filter").val();
    if (filter) {
      Cookies.set("category", filter);
      Cookies.set("pathname", pathname);
    }
    reload("recent_observations");
  })

  $(document).keyup(function(e) {
    if(e.key==='Enter' && $('#search_input').is(':focus')) $('#search_button').click();
  });

  $('.search-for').each(function() { 
    var el = $(this);
    el.click(function(){
      $('#search_input').val(el.text());
      $('#search_button').click();
    });
  });

  if (Cookies.get('category')) {
    $('#category_filter').val(Cookies.get('category'));
  }
  else {
    $('#category_filter').val("All Categories");
  }
  $('#search_input').val(Cookies.get('q'));
  $('#show_more').click();
}

function set_up_top_page() {
  if($('#all-regions-map').length==0) return; 

  var s = { lat: 0, lng: 0 };
  var map = new google.maps.Map(document.getElementById('all-regions-map'), { zoom: 2, center: s, controlSize: 20 });
  var infoWindow = new google.maps.InfoWindow({ content: "", disableAutoPan: true, });
    
  google.maps.event.addListenerOnce(map, 'idle', function() { 
    var bounds = new google.maps.LatLngBounds(null);

    if(_all_regions!=undefined) {
      var markers = [];
      var info_windows = [];

      for( var i = 0 ; i < _all_regions.length ; i++ ) {
        var r = _all_regions[i];
        var position = { lat: r.lat, lng: r.lng };

        const info_window = get_region_info_window(r);
        const marker = new google.maps.Marker({ position: position, map, title: r.name, animation: google.maps.Animation.DROP, icon: icon });//, visible: false });
        marker.addListener("click", () => { info_window.open({ anchor: marker, map, shouldFocus: false }); });

        bounds.extend(position);
        markers.push(marker);
        info_windows.push(info_window);
      }
    }  
       
    if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

    } else {
      map.setCenter(bounds.getCenter());
      map.fitBounds(bounds, 0);
      map.panToBounds(bounds);
    }

  });  
}

function get_region_info_window(region) {
  var content_string = '<div id="content">' +
                          '<div id="bodyContent">' +
                            '<a class="text-muted" href="' + region.url + '"/>' + region.name + '</a>' +
                          '</div>' +
                        '</div>';
  var info_window = new google.maps.InfoWindow({ content: content_string });

  return info_window;
}

function set_up_contest_page() {
  if($('#contest-map').length==0) return; 

  var s = { lat: 0, lng: 0 };
  var map = new google.maps.Map(document.getElementById('contest-map'), { zoom: 2, center: s, controlSize: 20 });
  var infoWindow = new google.maps.InfoWindow({ content: "", disableAutoPan: true, });
    
  google.maps.event.addListenerOnce(map, 'idle', function() { 
    var bounds = new google.maps.LatLngBounds(null);

    if(_participants!=undefined) {
      var markers = [];
      for( var i = 0 ; i<_participants.length ; i++ ) {
        var participant = _participants[i];
        var position = { lat: participant.lat, lng: participant.lng };

        const info_window = get_region_info_window(participant);
        const marker = new google.maps.Marker({ position: position, map, title: participant.name, icon: icon });
        marker.addListener("click", () => { info_window.open({ anchor: marker, map, shouldFocus: false }); });

        markers.push(marker);
        bounds.extend(position);
      }
    }    

    if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

    } else {
      map.setCenter(bounds.getCenter());
      map.fitBounds(bounds, 0);
      map.panToBounds(bounds);
    }

    for( var i = 0 ; i<_region_polygons.length ; i++ ) {
      var coordinates = _region_polygons[i]['coordinates'];
      var googlemaps_points = [];
      for( var j = 0 ; j<coordinates.length ; j++ ) googlemaps_points.push({ lng: coordinates[j][0], lat: coordinates[j][1] });
      var polygon = new google.maps.Polygon({ paths: googlemaps_points, fillColor: _colours[i%_colours.length] });
      polygon.setMap(map);
    }  

  });
}

function show_image(view_action, no_of_images) {
  var id;
  id = (view_action == 'prev' ? (_current_image - 1) : _current_image + 1);

  // Display image if it's withing range of array length
  if (id > 0 && id <= no_of_images) {
    document.getElementById("image" + id).style.display = "block";
    _current_image = id;
  }
  for(i = 1; i <= no_of_images; i++) {
    // Set display to none except current image which is being displayed
    if (i != _current_image) {
      document.getElementById("image" + i).style.display="none";
    }
  }
}

// Create div elements for displaying images on information window of map
function get_image_content(no_of_images, images) {
  var image_content = '';

  if (no_of_images > 0) {
    image_content = '<div style="float:right;padding: 10px;">';
    if (no_of_images > 1 ) {
      //Add Prev and next elements
      image_content += '<a class="slide round" onclick="show_image(' + "'prev'," +
                      no_of_images + ')">&#8249;</a>';
      image_content += '<a class="slide round" onclick="show_image(' +
                      "'next'," + no_of_images + ')">&#8250;</a>';
      image_content += '<div class="row mb-1"></div>'
    }
    for (i = 0; i < no_of_images; i++ ) {
      // By default display first image
      var display = (i == 0 ? 'display:block' : 'display:none');

      image_content += '<div id="image' + (i + 1) + '" style="' + display +'">' +
                      '<img class="thumbnail" style="cursor:pointer;" src="' +
                      images[i].url +
                    '" onclick="window.open(this.src, ' + "'_blank'"+');"></div>' ;
    }
    image_content += '</div>';
  }
  return image_content;
}

/* Fill the info window with observation details and images
   which will be displayed on map on click of marker */
function get_info_window_for_observation(info_window, id) {
   var observation;
   api_url = _api + '/observations/' + id;

  // Get observation details
  $.ajax({ url: api_url, type: 'get', contentType: 'application/json',
           async: false})
  .done(function(data, status) {
    observation = data['data']['observation'];
  });

  var no_of_images = observation.images.length;
  _current_image = 1;

  var common_name = '';

  if (observation.scientific_name != '') {
    common_name = (observation.common_name ? '<div class="row mb-0"></div> (' + observation.common_name + ')' : '');
  }
  else {
    common_name = (observation.common_name ? '<span class="info_text">' + observation.common_name + '</span>' : '');
  }
  var image_content = get_image_content(no_of_images, observation.images);
  const content_string = '<div id="obs_content" style="display:inline-block;">' +
                            '<div id="obs_body" style="float:left; padding:10px;">' +
                              '<h5>' + observation.scientific_name + '</h5>' +
                              common_name +
                              '<div class="row mb-2"></div>' +
                              'Created by: <span class="info_text">' + observation.creator_name + '</span>' +
                              '<div class="row mb-2"></div>' +
                              'Observed at: <span class="info_text">' + observation.observed_at + '</span>' +
                            '</div>' +
                            image_content +
                          '</div>';
  info_window.setContent(content_string);
  return info_window;
}

function close_info_windows(info_windows) {
  for( var i = 0 ; i < info_windows.length ; i++ ) {
    info_windows[i].close();
  }
}

function draw_neighboring_regions_polygon(map, bounds) {
  for( var i = 0 ; i < _neighboring_regions_json.length ; i++ ) {
    var nr = _neighboring_regions_json[i];
    var icons = [];
    if (i == 1) {
      icons = [{
        icon: dashed_line_symbol,
        offset:'0',
        repeat:'30px'
        }];
    }
    else {
      icons = [{
        icon: line_symbol,
        offset:'0',
        repeat:'1px'
        }];
      
    }
    
    for( var j = 0 ; j < nr.length ; j++ ) {

      var coordinates = nr[j]['coordinates'];
      var googlemaps_points = [];
      for( var k = 0 ; k <coordinates.length ; k++ ) googlemaps_points.push({ lng: coordinates[k][0], lat: coordinates[k][1] });
      var polygon = new google.maps.Polygon({ paths: googlemaps_points, visible: false, map: map });

      
      new google.maps.Polyline({
          strokeColor: 'white',
          strokeOpacity: 0,
          icons: icons,
          path: googlemaps_points,
          map: map
        });

      polygon.getPaths().forEach(function(path) {
        var ar = path.getArray();
        for(var j = 0, l = ar.length; j < l; j++) bounds.extend(ar[j]);
      });
    }
  }

}

function set_up_region_page() {
  if($('#region-map').length==0) return; 

  var s = { lat: 0, lng: 0 };
  var map = new google.maps.Map(document.getElementById('region-map'),
            { zoom: 2, center: s, controlSize: 20, mapTypeId: 'satellite'});
  var infoWindow = new google.maps.InfoWindow({ content: "", disableAutoPan: true, });
    
  google.maps.event.addListenerOnce(map, 'idle', function() { 
    var bounds = new google.maps.LatLngBounds(null);

    for( var i = 0 ; i<_polygon_json.length ; i++ ) {
      var coordinates = _polygon_json[i]['coordinates'];
      var googlemaps_points = [];
      for( var j = 0 ; j<coordinates.length ; j++ ) googlemaps_points.push({ lng: coordinates[j][0], lat: coordinates[j][1] });
      var polygon = new google.maps.Polygon({ paths: googlemaps_points, strokeColor: 'yellow', strokeWeight: 4 });
      polygon.setMap(map);

      polygon.getPaths().forEach(function(path) {
        var ar = path.getArray();
        for(var j = 0, l = ar.length; j < l; j++) bounds.extend(ar[j]);  
      });
    }
    if(typeof _neighboring_regions_json != "undefined") {
      draw_neighboring_regions_polygon(map, bounds);
    }
    if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

    } else {
      map.setCenter(bounds.getCenter());
      map.fitBounds(bounds, 0);
      map.panToBounds(bounds);
    }

    $.get(_api+_observations_filename, function() {})
    .done(function(data, status) {
      if(data['data']==undefined || data['data']['observations']==undefined || data['data']['observations'].length==0) {
        
      } else {
        var observations = data['data']['observations']

        var markers = [];
        var info_windows = [];
        var info_window = new google.maps.InfoWindow();

        for( var i = 0 ; i < observations.length ; i++ ) {
          obs = observations[i];
          var marker = new google.maps.Marker(
            { position: {lat: obs.lat, lng: obs.lng}, id: obs.id, icon: icon });
          marker.setMap(map);

          marker.addListener("click", function() {
              close_info_windows(info_windows);
              info_window = get_info_window_for_observation(info_window, this.id);
              info_window.open({ anchor: this, map, shouldFocus: false });
              info_windows.push(info_window);
           });

          markers.push(marker);
        } 
        const mc = new markerClusterer.MarkerClusterer({ map, markers });
      }
    })
    .fail(function(xhr, status, error) {})
    .always(function() {});

    if(location.href.indexOf('show_subregions=true')!=-1) {
      for( var i = 0 ; i<_subregions.length ; i++ ) {
        var circle = new google.maps.Circle({
          strokeColor: "#FF0000",
          strokeOpacity: 0.8,
          strokeWeight: 2,
          fillColor: "#FF0000",
          fillOpacity: 0.35,
          map,
          center: { lat: _subregions[i]['lat'], lng: _subregions[i]['lng'] },
          radius: _subregions[i]['radius_metres']
        });
      } 
    }
  });

}







// edit functions

function set_up_participations() {

  $('.participation_save_action').each(function() {
    var pa = $(this);
    var id = pa.attr('data-id');
    var verb = id=='new' ? 'POST' : 'PUT';
   
    pa.click(function() {
      var p = {};
      if(id!='new') p['id'] = parseInt(id);
      p['user_id'] = _user_id;
      p['status'] = $('.participation-modal-'+id+' .status_participation').val();
      if(p['status']==null) p['status'] = 'submitted';
      p['region_id'] = $('.participation-modal-'+id+' .region_id_participation').val();
      p['contest_id'] = $('.participation-modal-'+id+' .contest_id_participation').val();
      p['data_source_ids'] = [];
      $('input[name="data-sources-'+id+'"]:checked').each(function() { p['data_source_ids'].push(parseInt($(this).val())); });

      $.ajax({ url: (_api+'/participation'), type: verb, contentType: 'application/json',
               data: JSON.stringify({ 'participation': p }) })
      .done(function(data, status) {
        console.log(data);
        if(data['status']=='fail') {
          //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');
          console.log('fail');
        } else {
          reload();
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });

  });
}

function set_up_contests() {

  $('.contest_save_action').each(function() {
    var pa = $(this);
    var id = pa.attr('data-id');
    var verb = id=='new' ? 'POST' : 'PUT';
   
    pa.click(function() {
      var p = {};
      p['user_id'] = _user_id;
      if(id!='new') p['id'] = parseInt(id);
      p['status'] = $('.contest-modal-'+id+' .status_contest').val();
      p['title'] = $('.contest-modal-'+id+' .title_contest').val();
      p['description'] = $('.contest-modal-'+id+' .description_contest').val();
      p['starts_at'] = $('.contest-modal-'+id+' .starts_at_contest').val();
      p['ends_at'] = $('.contest-modal-'+id+' .ends_at_contest').val();

      $.ajax({ url: (_api+'/contest'), type: verb, contentType: 'application/json', data: JSON.stringify({ 'contest': p }) })
      .done(function(data, status) {
        console.log(data);
        if(data['status']=='fail') {
          //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');
          console.log('fail');
        } else {
          reload();
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });

  });
}

function set_up_regions() {
  $('#region').on('show.bs.modal', function() { Cookies.set('modal', 'region'); });
  $('#region').on('hide.bs.modal', function() { Cookies.remove('modal'); });

  var images = ['logo', 'header'];

  for( var j = 0 ; j < images.length ; j++ ) {
    $('.'+images[j]+'-region').each(function() {
      var i = $(this);
      var frameid = i.attr('data-frame-id');
      var image = images[j];
      
      i.change(function() { 
        $('.img-fluid.'+image+'-frame-'+frameid).attr('src', URL.createObjectURL(event.target.files[0]));
        getBase64(event.target.files[0], image);
      });
    });  

    $('.'+images[j]+'-region-remove').each(function() {
      var i = $(this);
      var frameid = i.attr('data-frame-id');
      var image = images[j];

      i.click(function() { 
        $('.img-fluid.'+image+'-frame-'+frameid).attr('src', '');
        $('.'+image+'-region.'+image+'-frame-'+frameid).val(null);
        _images[image] = null;
      });
    });        
  }

  $('.region_save_action').each(function() {
    var r = $(this);
    var id = r.attr('data-id');
    var verb = id=='new' ? 'POST' : 'PUT';
   
    r.click(function() {
      var p = {};
      p['user_id'] = _user_id;
      if(id!='new') p['id'] = parseInt(id);
      p['status'] = 'online'; //$('.region-modal-'+id+' .status_region').val();
      p['name'] = $('.region-modal-'+id+' .name_region').val().trim();
      p['description'] = $('.region-modal-'+id+' .description_region').val().trim();
      //p['population'] = $('.region-modal-'+id+' .population_region').val();
      p['logo_image_url'] = $('.region-modal-'+id+' .logo_url_region').val();
      p['header_image_url'] = $('.region-modal-'+id+' .header_url_region').val();
      p['region_url'] = $('.region-modal-'+id+' .region_url_region').val().trim();

      p['logo_image'] = $('img.logo-frame-'+id).attr('src');
      p['logo_image'] = _images['logo']==undefined ? p['logo_image'] : _images['logo'];
      
      p['header_image'] = $('img.header-frame-'+id).attr('src');
      p['header_image'] = _images['header']==undefined ? '' : _images['header'];
      var contest_ids = $('.region-modal-'+id+' .contest_filter').val();
      var lat_lng = []
      if ($('.region-modal-'+id+' .region_lat_lng').val() != '') {
        lat_lng = $('.region-modal-'+id+' .region_lat_lng').val().trim().split(",").map(function(item) {
          return item.trim();
        });
      }
      p['lat_input'] = lat_lng[0];
      p['lng_input'] = lat_lng[1];
      p['polygon_side_length'] = $('.region-modal-'+id+' .region_polygon_side').val().trim();
      if (p['polygon_side_length'] == '' && lat_lng.length > 0) {
        p['polygon_side_length'] = 1;
      }
      p['raw_polygon_json'] = [];
      $('.region-modal-'+id+' .polygon-json input').each(function() { 
        var val = $(this).val().trim();
        if(val.length) p['raw_polygon_json'].push(val); 
      });

      var failed = false;
      if(p['name'].length==0) { $('.name_region_v').removeClass('validation-ok'); failed = true; } else { $('.name_region_v').addClass('validation-ok'); }
      if(p['description'].length==0) { $('.description_region_v').removeClass('validation-ok'); failed = true; } else { $('.description_region_v').addClass('validation-ok'); }
      // if(p['logo_image'].length==0 && p['logo_image_url'].length==0) { $('.logo_region_v').removeClass('validation-ok'); failed = true; } else { $('.logo_region_v').addClass('validation-ok'); }
      if (lat_lng.length != 0) {
        if(isNaN(p['polygon_side_length'])) {
          $('.region_polygon_side_v').removeClass('validation-ok');
          failed = true;
        }
        else {
          $('.region_polygon_side_v').addClass('validation-ok');
        }
      }

      for( var i = 0 ; i <p['raw_polygon_json'].length ; i++ ) { 
        if(!validate_polygon_json(p['raw_polygon_json'][i])) { $('.polygon_json_region_v').removeClass('validation-ok'); failed = true; break; }  
        else { $('.polygon_json_region_v').addClass('validation-ok'); }
      }
     
      if(failed==false) {
        p['raw_polygon_json'] = "["+p['raw_polygon_json'].join(',')+"]";

        if (verb === 'PUT') {
          url = _api + '/region/' + id
        }
        else {
          url = _api + '/region'
        }
        $.ajax({ url: (url),
                 type: verb,
                 contentType: 'application/json',
                 data: JSON.stringify({ 'region': p, 'contest': contest_ids, 'gui_call': 'true' }) })
        .done(function(data, status) {
          if(data['status']=='fail') {
            console.log(data);
            console.log('in fail')
          } else {
            reload();
          }
        })
        .fail(function(xhr, status, error) {})
        .always(function() {});
      }
        
      return false;
    });

  });

  $('.region-modal').each(function() {
    var modalid = $(this).attr('id');
    var s = { lat: 0, lng: 0 };
    var map = new google.maps.Map(document.getElementById('map-'+modalid), { zoom: 2, center: s, controlSize: 20  });

    $('#polygon-json-'+modalid+' .polygon-draw').click(function() {
      // validate json
      draw_polygon($(this).parent().find('input'), map);
    });

    var drawingManager = new google.maps.drawing.DrawingManager({
      drawingControl: true,
      drawingControlOptions: { 
        position: google.maps.ControlPosition.TOP_CENTER,
        drawingModes: ['polygon']
      }
    });

    drawingManager.setMap(map);
    google.maps.event.addListener(drawingManager, 'polygoncomplete', write_polygon(modalid));
    
    google.maps.event.addListenerOnce(map, 'idle', function() { 
      var bounds = new google.maps.LatLngBounds(null);

      $('#polygon-json-'+modalid+' .polygon-draw').each(function() { $(this).click(); });

      $('#polygon-json-'+modalid+' .polygon-json input').each(function() {
        var polygon = get_polygon($(this));
        if(polygon!=null) {
          polygon.getPaths().forEach(function(path) {
            var ar = path.getArray();
            for(var i=0, l = ar.length; i <l; i++) bounds.extend(ar[i]);  
          });
        }  
      });

      if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

      } else {
        map.setCenter(bounds.getCenter());
        map.fitBounds(bounds, 0);
        map.panToBounds(bounds);
        map.setZoom(6);
      }  
    });
  });

}

function validate_polygon_json(str) {
  try {
    json = JSON.parse(str);

    if(json['type']==null || json['type']==undefined || json['type']!='Polygon') return false;
    if(json['coordinates']==null || json['coordinates']==undefined || !Array.isArray(json['coordinates'])) return false;

    $.each(json['coordinates'], function() {
      var lnglat = $(this);
      if(!Array.isArray(lnglat) || lnglat.length!=2) return false;
      if(typeof(lnglat[0])!='number' || lnglat[0]<-180.0 || lnglat[0]>180.0) return false;
      if(typeof(lnglat[1])!='number' || lnglat[1]<-90.0 || lnglat[1]>90.0) return false;
    });

    return true;
  } catch (e) {
    console.log('thrown in polygon validation');
    console.log(e);
  }
  return false;
}

function write_polygon(modalid) {
  return function(polygon) { 
    var points = polygon.getPath();
    var colour = set_parameters(polygon);
    var geojson_data = [];
    for (var i = 0; i < points.length; i++) geojson_data.push([points.getAt(i).lng(), points.getAt(i).lat()]);
    make_html(geojson_data, modalid, colour, polygon);
  };
}

function set_parameters(polygon) {
  var colour = _colours[_npolygons%_colours.length];
  _npolygons++;
  polygon.setOptions({ fillColor: colour, editable: true });
  return colour;
}

function make_html(polygon_geojson_data, modalid, colour, polygon) {
  var geojson = { 'type': 'Polygon', 'coordinates': polygon_geojson_data };
  var id = '#polygon-json-'+modalid;
  var new_input = $(id+' .polygon-json').first().clone();
  $(id).append(new_input);
  $(id+' .polygon-json input').last().val(JSON.stringify(geojson));
  $(id+' .polygon-json input').last().prop('readonly', true);
  $(id+' .polygon-json button.polygon-remove').last().removeAttr('disabled');
  $(id+' .polygon-json button.polygon-draw').last().prop('disabled', true);
  $(id+' .polygon-json span.polygon-colour').last().css('background-color', colour);
  var row = $(id+' .polygon-json').last();
  $(id+' .polygon-json button.polygon-remove').last().click(function() { 
    polygon.setMap(null); 
    row.remove(); 
  });
}

function draw_polygon(input, map) {
  var polygon = get_polygon(input);
  if(polygon==null) return;

  var colour = set_parameters(polygon);
  polygon.setMap(map);

  input.parent().find('span.polygon-colour').css('background-color', colour);

  input.parent().find('button.polygon-draw').attr('disabled', 'disabled');

  input.parent().find('button.polygon-remove').click(function() { 
    console.log('remove'); 
    polygon.setMap(null); 
    $(this).parent().parent().parent().remove(); 
  });
}

function get_polygon(input) {
  var polygon_text= input.val().trim();
  if(polygon_text.length==0) return null;

  var polygon_json = JSON.parse(polygon_text);
  var coordinates = polygon_json['coordinates'];
  var googlemaps_points = [];
  for( var i = 0 ; i<coordinates.length ; i++ ) googlemaps_points.push({ lng: coordinates[i][0], lat: coordinates[i][1] });
  var polygon = new google.maps.Polygon({ paths: googlemaps_points });

  return polygon;
}

function getBase64(file, name) {
   var reader = new FileReader();
   reader.readAsDataURL(file);
   reader.onload = function () { _images[name] = reader.result; };
   reader.onerror = function (error) { _images[name] = null; };
}












// login etc.

function set_up_authentication() {
  $('#signup').on('show.bs.modal', function() { Cookies.set('modal', 'signup'); });
  $('#login').on('show.bs.modal', function() { Cookies.set('modal', 'login'); });
  $('#profile').on('show.bs.modal', function() { Cookies.set('modal', 'profile'); });
  $('#signup').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#login').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#profile').on('hide.bs.modal', function() { Cookies.remove('modal'); });

  $('#already_have_an_account').click(function() { _signup_modal.hide(); _login_modal.show(); });
  $('#signup_from_login').click(function() { _login_modal.hide(); _signup_modal.show(); });
  $('#signup_success').on('hide.bs.modal', function() { _login_modal.show(); });

  $(document).keyup(function(e) {
    $('.signup-modal').each(function() {
      var m = $(this);
      if(m.hasClass('show')) get_signup_params(m.attr('id'));
    });
    
    if($('#profile.show').length) get_signup_params('profile');


    if($('#login.show').length && e.key==='Enter') $('#login_action').click();
  });

  $('.signup-modal').each(function() {
    var id = $(this).attr('id');

    $('#'+id+'_action').click(function() { 
      p = get_signup_params(id);

      $.post(_api+'/user' ,p)
      .done(function(data, status) {
        if(data['status']=='fail') {
          if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');

        } else {
          if(id=='signup') {
            $('#email_login').val($('#signup .email').val());
            _signup_modal.hide();
            _signup_success_modal.show();
          } else {
            reload();
          } 
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });
  });   

  $('#profile_action').click(function() { 
    p = get_signup_params('profile');
    $.ajax({ url: (_api+'/user'), type: 'PUT', contentType: 'application/json', data: JSON.stringify(p) })
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function(){ reload(); });
    return false;
  });

  $('#login_action').click(function(){ 
    var p ={};
    p['email'] = $('#email_login').val();
    p['password'] = $('#password_login').val();
    login(p);
    return false;
  });

  $('.logout_action').each(function() {
    $(this).click(function() { 
      $.post(_api+'/user/logout')
      .done(function(data, status) {})
      .fail(function(xhr, status, error) {})
      .always(function(){ Cookies.remove('modal'); reload(); });
      return false;
    });  
  });

  $('.close_account_action').each(function() {
    $(this).click(function() { 
      $.ajax({ url: (_api+'/user'), type: 'DELETE', contentType: 'application/json' })
      .done(function(data, status) {})
      .fail(function(xhr, status, error) {})
      .always(function(){ Cookies.remove('modal'); reload(); });
      return false;
    });  
  });




  $('#login input').each(function() { 
    $(this).focus(function() { $('#login span').addClass('validation-ok'); });
  });

  $('.signup-modal').each(function() { 
    var id = $(this).attr('id');
    $('#'+id+' input').each(function() { 
      $(this).focus(function() { $('#'+id+' span').addClass('validation-ok'); });
    });
  });
}

function get_signup_params(modal) {
  var p = {}
  var organization_name = $('#'+modal+' .organization_name');
  var email = $('#'+modal+' .email');
  var password = $('#'+modal+' .password');
  var action = $('#'+modal+'_action');

  p['organization_name'] = organization_name.val().trim();
  p['email'] = email.val().trim().toLowerCase();   
  if(password.length) p['password'] = password.val();

  var all_present = true;
  if(p['organization_name'].length==0) all_present = false;
  if(p['email'].length==0) all_present = false;
  if(password.length && p['password'].length==0) all_present = false;
  if(!all_present) return true;

  var failed = false;
  var organization_name_v = $('#'+modal+' .organization_name_v');
  var email_v = $('#'+modal+' .email_v');
  var password_v = $('#'+modal+' .password_v');  
  if(p['organization_name'].length==0) { organization_name_v.removeClass('validation-ok'); failed = true; } else { organization_name_v.addClass('validation-ok'); }
  if(_re.test(p['email'])==false) { email_v.removeClass('validation-ok'); failed = true; } else { email_v.addClass('validation-ok'); }
  if(password.length && p['password'].length<6) { password_v.removeClass('validation-ok'); failed = true; } else { password_v.addClass('validation-ok'); }

  //if(failed) action.attr('disabled', 'disabled');
  //else action.removeAttr('disabled');

  action.removeAttr('disabled');  

  p = { 'user': p };

  return (failed ? null : p);
}

function login(params) {
  $.post(_api+'/user/login', params)
  .done(function(data, status) {
    if(data.status=='fail') $('#login .validation-ok').removeClass('validation-ok');
    else { Cookies.remove('modal'); reload(); }
  })
  .fail(function(xhr, status, error) {
    $('#login .validation-ok').removeClass('validation-ok');
  });
}

function set_month_filter(month_filter) {
  $('#month_filter').multiselect({ templates: {
      button: '<button type="button" class="multiselect" data-bs-toggle="dropdown" aria-expanded="false"><span class="multiselect-selected-text"></span></button>',
    },
    includeSelectAllOption: true,
    buttonClass:'custom-select',
    inheritClass:true,
    allSelectedText: 'All months',
    nSelectedText: 'months',
    numberDisplayed: 2,
    selectAllNumber: false,
    buttonWidth: '100%'
  });

  if (month_filter != '') {
    $('#month_filter').multiselect('select', month_filter);
    $("#month_filter").multiselect('updateButtonText');
  } else {
    $("#month_filter").multiselect('selectAll', false);
    $("#month_filter").multiselect('updateButtonText');
  }
  var months_selected = $("#month_filter option").not(":selected").length;
  if (months_selected === 0) {
    $("#all_months").val("All");
  }
  $("#month_filter").change(function() {
    var months_selected = $("#month_filter option").not(":selected").length;
    if (months_selected != 0) {
      $("#all_months").val("");
    }
    else {
      $("#all_months").val("All");
    }
  });
}

function set_year_filter(year_filter) {
  $('#year_filter').multiselect({ templates: {
       button: '<button type="button" class="multiselect" data-bs-toggle="dropdown" aria-expanded="false"><span class="multiselect-selected-text"></span></button>',
        },
    includeSelectAllOption: true,
    buttonClass:'custom-select',
    inheritClass:true,
    allSelectedText: 'All years',
    nSelectedText: 'years',
    numberDisplayed: 2,
    selectAllNumber: false,
    buttonWidth: '100%'
  });
  if (year_filter != '') {
    $('#year_filter').multiselect('select', year_filter);
    $("#year_filter").multiselect('updateButtonText');
  } else {
    $("#year_filter").multiselect('selectAll', false);
    $("#year_filter").multiselect('updateButtonText');
  }
  var year_selected = $("#year_filter option").not(":selected").length;
  if (year_selected === 0) {
    $("#all_years").val("All");
  }
  $("#year_filter").change(function() {
    var year_selected = $("#year_filter option").not(":selected").length;
    if (year_selected != 0) {
      $("#all_years").val("");
    }
    else {
      $("#all_years").val("All");
    }
  });
}


function set_contest_filter(contest_filter, region_id) {
  var elem_id = 'contest_filter';
  if (region_id) {
    elem_id = 'contest_filter_' + region_id;
  }
  $("#" + elem_id).multiselect({ templates: {
      button: '<button type="button" class="multiselect" data-bs-toggle="dropdown" aria-expanded="false"><span class="multiselect-selected-text"></span></button>',
    },
    includeSelectAllOption: true,
    buttonClass:'custom-select',
    inheritClass:true,
    allSelectedText: 'All Contests',
    nonSelectedText: '-- Select Contest --',
    nSelectedText: 'contests',
    numberDisplayed: 1,
    selectAllNumber: false,
    buttonWidth: '100%'
  });

  var contest_ids = new Array();
  contest_ids = JSON.parse(contest_filter);
  if (contest_ids.length > 0) {
    $("#" + elem_id).multiselect('select', contest_ids);
    $("#" + elem_id).multiselect('updateButtonText');
  }
}


