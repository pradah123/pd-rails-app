class Constant < ApplicationRecord
	# 
	# the bioscores involve a number of constants, which
	# can be managed by operations staff via this model in 
	# rails admin.
	#s 

  def self.get_all_constants
    return Constant.all.pluck(:name, :value).map { |name, value| { "#{name}": value } }.reduce Hash.new, :merge
  end
end
