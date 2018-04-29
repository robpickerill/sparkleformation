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
    user_id do
      type 'String'
      descrption 'AWS Account ID'
      default account_id
    end
    s3_lambda_bucket do
      type 'String'
      description 'Lambda function bucket'
      default 'elb-logs-lambda'
    end
    s3_lambda_key do
      type 'String'
      description 'Lamba function file'
      default 'elblog-lambda.zip'
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
        tags _array(
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
                transition_in_days ref!(:log_trans_glacier)
              end
              expiration_in_days ref!(:log_expire_days)
            }
          )
        end
      notification_configuration do
        lambda_configurations _array(
          -> {
            event 's3:ObjectCreated:*'
            function attr!(:elb_logs_lambda, 'Arn')
          }
        )
      end
      end
  end

  resources.elb_logs_s3_policy do
    type 'AWS::S3::BucketPolicy'
      properties do
        bucket join!([ref!(:bucket_name), ref!(:namespace)], options: {delimiter: '-'})
          policy_document do
            id join!([ref!(:bucket_name), ref!(:namespace), "policy"], options: {delimiter: '-'})
            version '2012-10-17'
            statement _array(
              -> {
                sid 'Stmt1429136633762'
                action _array(
                  's3:PutObject'
                  )
                effect 'Allow'
                resource join!(['arn:aws:s3:::', ref!(:bucket_name), '-', ref!(:namespace), '/AWSLogs/', ref!(:user_id), '/', ], options: {delimiter: ''})
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

  resources.elb_logs_lambda_role do
    type 'AWS::IAM::Role'
    properties do
      role_name join!([ref!(:bucket_name), ref!(:namespace), "policy"], options: {delimiter: '-'})
      managed_policy_arns _array(
        'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole'
      )
      assume_role_policy_document do
        version '2012-10-17'
        statement _array(
            -> {
              effect 'Allow'
              principal do
                service _array(
                    'lambda.amazonaws.com'
                )
              end
              action _array(
                'sts:AssumeRole'
              )
            }
          )
        end
      end
  end

  resources.elb_logs_lambda_permissions do
    type 'AWS::Lambda::Permission'
    properties do
      action 'lambda:InvokeFunction'
      function_name attr!(:elb_logs_lambda, 'Arn')
      principal 's3.amazonaws.com'
      source_account ref!(:user_id)
      source_arn 'arn:aws:s3:::' + join!([ref!(:elb_logs_s3), ref!('AWS::StackName')], options: {delimiter: '.'})
    end
   end

  resources.elb_logs_lambda do
    type 'AWS::Lambda::Function'
      properties do
        code do
          s3_bucket ref!(:s3_lambda_bucket)
          s3_key ref!(:s3_lambda_key)
        end
        function_name join!([ref!(:bucket_name), ref!(:namespace)], options: {delimiter: '-'})
        handler 'index.handler'
        memory_size '128'
        timeout '3'
        runtime 'nodejs4.3'
        role join!(['arn:aws:iam::', ref!(:user_id), ':role/lambda-elb-logs'], options: {delimiter: ''})
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
      end
  end

  outputs do
    Region do
      value region!
    end
    WebsiteURL do
      value attr!("elb_logs_s3".to_sym, :WebsiteURL)
    end
    DomainName do
      value attr!("elb_logs_s3".to_sym, :DomainName)
    end
    ARN do
      value attr!("elb_logs_s3".to_sym, :Arn)
    end
  end


end
