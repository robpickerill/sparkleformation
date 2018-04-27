SparkleFormation.dynamic(:s3bucket) do |name, opts={}|

  parameters do
    set!("#{name}_bucket_name".to_sym).type 'String'
    namespace do
      type 'String'
      default 'testing'
    end
    storagepolicy do
      type 'String'
      default 'STANDARD'
      allowed_values registry!(:s3_storageclass)
    end
  end

  outputs do
    WebsiteURL do
      description "URL: #{name}"
      value attr!("#{name}_s3_bucket".to_sym, :WebsiteURL)
    end
    DomainName do
      description "Domain name: #{name}"
      value attr!("#{name}_s3_bucket".to_sym, :DomainName)
    end
    ARN do
      value attr!("#{name}_s3_bucket".to_sym, :Arn)
    end
  end

  dynamic!(:s3_bucket, name) do
    properties do
      bucket_name ref!("#{name}_bucket_name".to_sym)
      tags _array(
      -> {
        key "Name"
        value "#{name}"
      },
      -> {
        key "Env"
        value "Test"
      },
      -> {
        key "Namespace"
        value ref!(:namespace)
      }
    )
    end
  end

end
