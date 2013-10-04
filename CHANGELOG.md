# Change Log

## 2013-10-25
This release represents a complete refactor of NYU's PDS code for
clarity and ease of management. The code is __completely different__
from previous releases.

Functionally, the difference is less drastic, though there are changes.
They are highlighted below:

- __Responsive UI__ :iphone:  
  PDS now uses the NYU Libraries [shared UI assets](https://github.com/NYULibraries/nyulibraries_assets)
  :gem: which is built on top of Twitter's [Bootstrap](http://getbootstrap.com/2.3.2/).
  This means that library login pages are now [responsive](http://en.wikipedia.org/wiki/Responsive_web_design),
  so login should be more usable on all your devices :smiley:

- __Abu Dhabi, Shanghai and Health Sciences, Welcome to the Party__  
  With the adoption of the NYU Libraries [shared UI assets](https://github.com/NYULibraries/nyulibraries_assets)
  we get login screens styled for NYU Abu Dhabi, NYU Shanghai and the NYU Health Sciences Library for free :tada:

- __Stop Using the Password Anti-Pattern__  
  We used to employ the [Password Anti-Pattern](http://adactio.com/journal/1357/) for NYU users with a NetID and password.
  That's pretty bad :cry:, so we stopped with this release. Instead users are directed to the 
  [NYU Login page](https://login.nyu.edu/sso/UI/Login) via a  
  [![GIGANTIC TORCH](https://raw.github.com/NYULibraries/pds-custom/master/assets/images/nyu.png)](https://logindev.library.nyu.edu/pds)

- __Shibboleth Integration__  
  Previously, NYU employed a hybrid single sign-on solution, using [OpenSSO](http://en.wikipedia.org/wiki/OpenSSO)
  to provide a single sign-on for NYU systems and [Shibboleth](http://shibboleth.net/) to provide single sign-on 
  for external systems. OpenSSO is no more, so we integrated 
  [PDS with Shibboleth](https://github.com/NYULibraries/pds-custom/wiki/NYU-Shibboleth-Integration).

- __Single Sign-On, Mostly__  
  Previously, most of our applications (the exceptions being Primo and Aleph) were able to determine on their
  own if a user was logged into another of NYU's single sign-on systems (e.g. NYU Home). Making this determination
  at the local application level meant that SSO checks didn't adversely affect performance. With the Shibboleth
  Integration, our applications are no longer able to make this determination on their own. 
  
  Given this situation, we had a design choice to make: degrade the speed with which our applications resolve by
  checking PDS to see if an NYU SSO session (e.g. NYU Home) exists, or ignore the possibility of an NYU SSO session
  and maintain the current speed. We decided on a compromise approach that checks with PDS the first time a user hits
  the application, but ignores the possibility on subsequent calls in the same browser session. The precedent for
  the decision is Primo and Aleph which have always worked in this manner.  The __exception__ to this method is e-Shelf,
  which ignores the possibility of an NYU SSO session altogether. This is a know issue and an e-Shelf upgrade is 
  scheduled for Spring 2014 that will rectify the problem.
  
  Since stories are a much better way to illustrate what this means, here are three:  
  1. __Story:__ [Hannan](https://github.com/hab278) goes to BobCat and clicks the Journal tab.
     He then __logs in__ to the NYU Home research channel, and does a search in the journals tab.
     On getting his results, he is __not logged in__ to BobCat.

     __Explanation:__ Hannan had already hit BobCat and GetIt before logging into NYU Home, so when he went
     back to those applications, he wasn't automatically logged in.  In order to login, he needs to click login and 
     he will be automatically logged in, without having to enter his NetID and password.  
  2. __Story:__ [Kristina](https://github.com/kristinarose) __logs in__ to the NYU Home research channel
     and does a search in the journals tab. On getting her results, she is __logged in__ to BobCat.

     __Explanation:__ Since the first time Kristina hit the NYU Libraries' GetIt application was after she 
     logged into NYU Home, GetIt attempted to log her in via her NYU session and succeeded.
  3. __Story:__ [Scot](https://github.com/scotdalton) logs into the NYU Home research channel.  He clicks on the "My Library Account" link.
     He is __not logged in__ to his e-Shelf.

     __Explanation:__ The e-Shelf is the exception, so even though Scot logged into NYU Home, he still needs to click
     login and he will be automatically logged in, without having to enter his NetID and password.

- __Sane Default Institution__  
  PDS used to default to NYSID if a proper institute wasn't given.  We thought this was a little crazy so we
  [changed it to default NYU](https://github.com/NYULibraries/pds/blob/development/program/PDSTabService.pm#L252).

- __Automated Tests__  
  This isn't really a change in functionality, but's it's _AWESOME_ :sparkles: so we wanted to mention it.
  We've expanded the [BobCat automated tests](https://github.com/NYULibraries/bobcat_automated_tests)
  for login. This means that all those hours that actual humans slogged through testing login (or maybe didn't)
  are a thing of the past.  We'll let a :computer: handle it from now on. 
