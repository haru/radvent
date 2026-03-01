# Base class for all ActiveRecord models in the application.
#
# This abstract class provides common functionality for all models in the Radvent application.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
