#
# Require this file to grab the Pantry unit test environment.
# This environment includes setup helpers to ensure Celluloid is running,
# as well as a few mocks (ui and fakefs) as well as helpers to facilitate
# testing Pantry plugins.
#

require 'pantry'
require 'celluloid/test'
require 'pantry/test/support/minitest'
require 'pantry/test/support/matchers'
require 'pantry/test/support/mock_ui'
require 'pantry/test/support/fake_fs'
