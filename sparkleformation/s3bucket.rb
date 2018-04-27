SparkleFormation.new(:s3bucket, :provider => :aws).load(:base).overrides do

  dynamic!(:s3bucket, :elb_logs)

end
