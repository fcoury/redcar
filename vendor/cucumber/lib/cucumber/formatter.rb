%w{color_io pretty progress profile rerun html}.each{|n| require "cucumber/formatter/#{n}"}