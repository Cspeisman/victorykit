var spinner;

function diff(array1, array2) {
  var a1 = $.map(array1, function(item) {return item.uid;});
  var a2 = $.map(array2, function(item) {return item.uid;});
  var uids = a1.filter(function(i) {
    return a2.indexOf(i) < 0;
  });
  return array1.filter(function(i) { return uids.indexOf(i.uid) >= 0; });
}

function createSpinner() {
  var opts = {
    lines: 13, // The number of lines to draw
    length: 7, // The length of each line
    width: 4, // The line thickness
    radius: 10, // The radius of the inner circle
    corners: 1, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    color: '#000', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 60, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px
  };
  var target = $('#facebookFriendsModal .modal-body').get(0);
  return new Spinner(opts).spin(target);
}

function buildMultiFriendSelector() {
  $(VK.recommended_friends).each(function(index, item) {
    var checked = item.preselect ? 'checked' : '';
    var li = $('<li><input type="checkbox" '+checked+' value="'+item.uid+'"/>'+item.name+'</li>');
    var id = '#' + item.type;
    $('.facebook_friend_widget ' + id + ' ul').append(li);
    $(id).removeClass('hide');
  });
}

function postOnFriendsTimeline()
{
  var domain = location.href.replace(/\?.*/,"");
  var memberHash = VK.current_member_hash;
  var url = [domain, '?suggested_ref=', memberHash].join('');
  var message = $('#message-to-friends').val();

  function postOnFacebook(user, action, data, callback) {
    if(!callback) {
      callback = function(){};
    }
    FB.api('/'+user+'/'+action,'post', data, callback);
  }

  postOnFacebook('me', 'watchdognet:sign', {petition: url},
    function(response) {
      $(friendUids()).each(function(index, uid) {
        postOnFacebook(uid, 'feed', {link: url, message: message});
      });
      $('#facebookFriendsModal').modal('toggle');
    }
  );

  function friendUids() {
    var uids = [];
    $('#suggested input[type="checkbox"]').each(function(index, item) {
      if($(item).attr('checked')) {
        uids.push($(item).val());
      }
    });
    return uids;
  }
}

function findRecommendedFriends(groups) {
  var tier1 = diff(groups.friends_notifying, groups.friends_involved);
  var friends_not_involved = diff(groups.friends, groups.friends_involved);
  var tier2 = diff(friends_not_involved, tier1);
  var tier3 = diff(groups.friends, tier1.concat(tier2));
  VK.recommended_friends = [];

  var suggested = tier1.concat(tier2);
  remaining = suggested.slice(25);
  suggested = suggested.slice(0, 25);
  remaining = remaining.concat(tier3);

  $(suggested).each(function(index, friend){
    VK.recommended_friends.push({uid: friend.uid, name: friend.name, type: 'suggested', preselect: true});
  });

  $(remaining).each(function(index, friend){
    VK.recommended_friends.push({uid: friend.uid, name: friend.name, type: 'other', preselect: false});
  });

  buildMultiFriendSelector();
  spinner.stop();
  $('.btn-success').click(function(event){
    postOnFriendsTimeline();
  });
}

function queryFacebook(query, groups) {
  FB.api("/fql?q=" +  encodeURIComponent(JSON.stringify(query)),
    function(response) {
      $(response.data).each(function(index, object) {
        var name = object.name;
        var resultSet = object.fql_result_set;
        $(resultSet).each(function(i, friend) {
          if(!groups[name]) { return; }
          groups[name].push(friend);
        });
      });

      findRecommendedFriends(groups);
    }
  );
}

function getFriendsWithAppInstalled() {
  var groups = {
    friends_notifying: [],
    friends_involved: [],
    friends: []
  };
 
  var query = {
    "friend_ids":"select uid2 from friend where uid1 = me()",
    "friends_notifying":"select name, uid from user where uid "+
      "in (select sender_id from notification where recipient_id = me()) "+
      // "order by profile_update_time desc limit 50", 
      "order by profile_update_time desc", 
    "friends_involved":"select name, uid from user where uid in "+
      "(select user_id from url_like where user_id in (select uid2 from #friend_ids) "+
      // "and strpos(url, 'watchdog.net') > 0) order by profile_update_time desc limit 50", 
      "and strpos(url, 'watchdog.net') > 0) order by profile_update_time desc", 
    "friends":"select name, uid from user where uid in (select uid2 from #friend_ids) "+
      // "order by profile_update_time desc limit 50"
      "order by profile_update_time desc"
  };

  queryFacebook(query, groups);
}

function submitAppRequest() {
  $("#thanksModal").modal('toggle');
  FB.login(function (response) {
    if (response.authResponse) {
      $('#facebookFriendsModal').modal('toggle');
      spinner = createSpinner();
      getFriendsWithAppInstalled();
     }
  }, {scope: 'publish_actions, manage_notifications'});
}

function bindFacebookSuggestedButton() {
  $('.fb_request_btn').click(submitAppRequest);  
}
