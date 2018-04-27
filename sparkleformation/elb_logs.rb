SparkleFormation.new(:s3elblogs, :provider => :aws).load(:base).overrides do

  parameters do
    bucket_name do
      type 'String'
      default 'elb-logs'
    end
    namespace do
      type 'String'
      default 'testing'
    end
    log_trans_glacier do
      type 'Number'
      description 'Transition logs to glacier'
      default 3
    end
    log_expire_days do
      type 'Number'
      description 'S3 Bucket Lifecycle Expiration in Days'
      default 10
    end
  end

  mappings.policy_principal do
    set!('us-east-1'._no_hump, :elb_account_id => '127311923021')
    set!('us-west-2'._no_hump, :elb_account_id => '797873946194')
  end

  resources.elb_logs_s3 do
    type 'AWS::S3::Bucket'
      properties do
        bucket_name join!([ref!(:bucket_name), ref!(:namespace)], options: {delimiter: '-'})
        tags array!(
          -> {
            key "Name"
            value join!([ref!(:bucket_name), ref!(:namespace)], options: {delimiter: '-'})
          },
          -> {
            key "Namespace"
            value ref!(:namespace)
          },
          -> {
            key "Env"
            value "dev"
          }
        )
        lifecycle_configuration do
          rules _array(
            -> {
              status 'Enabled'
              id join!([ref!(:log_trans_glacier), 'transition', ref!(:log_expire_days), 'expire'], options: {delimiter: '-'})
              prefix ""
              transition do
                storageClass "GLACIER"
                transitionInDays ref!(:log_trans_glacier)
              end
              expirationInDays ref!(:log_expire_days)
            }
          )
        end
      end
  end

  resources.elb_logs_s3_policy do
    type 'AWS::S3::BucketPolicy'
      properties do
        bucket join!([ref!(:bucket_name), ref!(:namespace)], options: {delimiter: '-'})
          policyDocument do
            id join!([ref!(:bucket_name), ref!(:namespace), "policy"], options: {delimiter: '-'})
            version '2012-10-17'
            statement _array(
              -> {
                sid 'Stmt1429136633762'
                action _array(
                  's3:PutObject'
                  )
                effect 'Allow'
                resource join!(['arn:aws:s3:::', ref!(:bucket_name), '-', ref!(:namespace), '/*'], options: {delimiter: ''})
                principal do
                  a_w_s _array(
                    map!(:policy_principal, region!, :elb_account_id)
                  )
                end
              }
            )
          end
      end
  end

  outputs do
    WebsiteURL do
      value attr!("elb_logs_s3".to_sym, :WebsiteURL)
    end
    DomainName do
      value attr!("elb_logs_s3".to_sym, :DomainName)
    end
    ARN_S3 do
      value attr!("elb_logs_s3".to_sym, :Arn)
    end
    ARN_S3_POLICY do
      value attr!("elb_logs_s3_policy".to_sym, :Arn)
    end
  end


end
