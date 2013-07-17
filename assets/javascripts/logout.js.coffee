#= require application/jquery
logout = (target_url) -> 
  for system_key in _system_map
      for cookie_key in _system_map[system_key].cookies
        expire_cookie _system_map[system_key].cookies[cookie_key]
  window.location = "#{target_url}"
  
expire_cookie = (expired_cookie) ->
  expired_cookie += "=;expires=Thu, 01-Jan-1970 00:00:01 GMT;path=/;domain=.library.nyu.edu"
  document.cookie = expired_cookie
