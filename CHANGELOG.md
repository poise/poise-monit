# Poise-Monit Changelog

## v1.6.0

* Update to `poise-languages` 2.0. None of the changed APIs are used in this
  project so this is only a semver dependency bump.

## v1.5.2

* Compat fix for poise-service 1.3.1.

## v1.5.1

* Make the `monit_template` option from 1.5.0 actually work.

## v1.5.0

* Allow overriding the template used for the `monit` service provider.

## v1.4.0

* Allow tuning the timeout and wait for `monit_service` via node attributes.

## v1.3.0

* More complete `:dummy` provider for weird install conditions.

## v1.2.1

* Fix static binary URLs for recent versions of Monit on AIX.

## v1.2.0

* New resource `monit_check` for more easily creating service checks.

## v1.1.0

* Improve compatibility with Chef 12.4 and earlier.
* New property for `monit` resource: `demon_delay` to control start delay.
* More verbose output from Monit when Chef is running in debug mode.
* Update binaries provider for Monit 5.16.

## v1.0.1

* Small fix for compatibility with `poise-service-monit`.

## v1.0.0

* Initial release!
