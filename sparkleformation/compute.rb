SparkleFormation.new(:compute, :provider => :aws).load(:base).overrides do
  dynamic!(:node, :test)
end
