The MinnPost Dashboard is an internal tool for tracking and displaying metrics across the organization.  It is based on the [Dashing](http://shopify.github.com/dashing) platform.  The main feature added is the ability to periodically save metrics so that historical records can be kept.

## Install and configure

1. `gem install dashing`
1. Set authentication token.  `export DASHING_AUTH_TOKEN=your_token`
1. Set OAuth domain.  `export DASHING_OAUTH_DOMAIN=minnpost.com`
1. `bundle install && bundle exec rake db:migrate`

### Setting up services

This project connects to many different services, the following tries to document how to set them up for connection:

#### Google API for analytics.

To access Google Analytics, we must use the Google API.  Some help about keys [here](http://ar.zu.my/how-to-store-private-key-files-in-heroku/).

1. Go the [Google API Console](https://code.google.com/apis/console/) and create a new project.
1. Enable Google Analytics
1. Under API Access, click Create an OAuth 2.0 client ID
1. Give it a product name
1. Choose Service Account
1. Download key
1. Add the email address for the key to Google Analytics access
1. Set environemtn variable for email: `export DASHING_GAPI_ISSUER=XXXX@developer.gserviceaccount.com`
1. Parse out OpenSSL cert using `irb`: `Google::APIClient::KeyUtils.load_from_pkcs12('<PATH_TO_KEY>', 'notasecret').inspect`.  This will output a multi-line key string.  Set it as an environment variable and make sure to use double quotes: `export DASHING_GAPI_PRIVATE_KEY="<LONG_KEY>"`

## Run

1. `dashing start`

## Deploy

Deployable on Heroku, see [these instructions](https://github.com/Shopify/dashing/wiki/How-to%3A-Deploy-to-Heroku).

Set configuration:

1. `heroku config:set RACK_ENV=production`
1. `heroku config:add DASHING_AUTH_TOKEN=your_token`
1. `heroku config:add DASHING_OAUTH_DOMAIN=minnpost.com`
1. `heroku config:add DASHING_GAPI_ISSUER=XXXX@developer.gserviceaccount.com` (See Google API keys above)
1. `heroku config:add DASHING_GAPI_PRIVATE_KEY="<LONG_STRING>"` (See Google API keys above)
    
Install a database

1. `heroku addons:add heroku-postgresql`
1. This does not seem right, but the app requires a `DATABASE_URL` which heroku should make on deploy, but this is not working, so manually do this.  See your DB config with `heroku config`, then: `heroku config:add DATABASE_URL=the_string_from_the_other_config_value`
1. `heroku run bundle exec rake db:migrate`

Install New Relic monitoring:

In order to keep the Heroku instance running so that the long form scheduled tasks can run, New Relic is used to ping the website often.  This is hackish but allows to use Heroku.

1. `heroku addons:add newrelic:standard`
1. `heroku config:add NEW_RELIC_APP_NAME=<YOUR_APP_NAME>`
1. Once data is available in the New Relic dashboard, go to Settings > Availability monitoring and set a ping.


## Authentication

Authentication is setup to use Google OAuth.  Set up with [these instructions](https://github.com/Shopify/dashing/wiki/How-to%3A-Add-authentication#authenticating-with-google-apps).