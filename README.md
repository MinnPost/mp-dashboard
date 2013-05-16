The MinnPost Dashboard is an internal tool for tracking and displaying metrics across the organization.  It is based on the [Dashing](http://shopify.github.com/dashing) platform.  The main feature added is the ability to periodically save metrics so that historical records can be kept.

## Install and configure

1. `gem install dashing`
1. Set authentication token.  `export DASHING_AUTH_TOKEN=your_token`
1. Set OAuth domain.  `export DASHING_OAUTH_DOMAIN=minnpost.com`
1. `bundle install && bundle exec rake db:migrate`

## Run

1. `dashing start`

## Deploy

Deployable on Heroku, see [these instructions](https://github.com/Shopify/dashing/wiki/How-to%3A-Deploy-to-Heroku).

Set configuration:

1. `heroku config:add DASHING_AUTH_TOKEN=your_token`
1. `heroku config:add DASHING_OAUTH_DOMAIN=minnpost.com`
    
Install a database

1. `heroku addons:add heroku-postgresql`
1. This does not seem right, but the app requires a `DATABASE_URL` which heroku should make on deploy, but this is not working, so manually do this.  See your DB config with `heroku config`, then: `heroku config:add DATABASE_URL=the_string_from_the_other_config_value`
1. `heroku run bundle exec rake db:migrate`

## Authentication

Authentication is setup to use Google OAuth.  Set up with [these instructions](https://github.com/Shopify/dashing/wiki/How-to%3A-Add-authentication#authenticating-with-google-apps).