require 'base64'
require 'openssl'
require 'digest/sha1'

class UploadsController < ApplicationController
  
  
  # Using dropzone to upload straight to S3
  # https://github.com/enyo/dropzone/issues/33
  #
  # Browser Uploads to S3 using HTML POST Forms
  # http://aws.amazon.com/articles/1434
  #
  # Direct Browser Uploading – Amazon S3, CORS, FileAPI, XHR2 and Signed PUTs
  # http://www.ioncannon.net/programming/1539/direct-browser-uploading-amazon-s3-cors-fileapi-xhr2-and-signed-puts/
  #
  # Configuring CORS on an S3 bucket
  # https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
  #
  # Granting Access to a Single S3 Bucket Using Amazon IAM
  # http://mikeferrier.com/2011/10/27/granting-access-to-a-single-s3-bucket-using-amazon-iam/
  def policies
    ext = File.extname(params[:name])
    unique_file_name = params.values_at(:name, :size, :type).join(".")
    filename = Digest::SHA1.hexdigest(unique_file_name) + ext
    object_name = "uploads/#{current_user.id}/#{filename}"
    
    policy_document = MultiJson.dump({
      "expiration" => 1.day.from_now.utc.iso8601,
      "conditions" => [
        {"bucket" => Houston.config.s3[:bucket]},
        ["starts-with", "$key", "uploads/"],
        {"acl" => "public-read"},
        {"success_action_status" => "201"},
        ["content-length-range", 0, 3 * 1048576] # 3 MB
      ]})
    
    policy = Base64.encode64(policy_document).gsub("\n","")
    
    signature = Base64.encode64(
        OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new("sha1"), 
            Houston.config.s3[:secret], policy)
        ).gsub("\n","")
    
    render json: {
      "AWSAccessKeyId" => Houston.config.s3[:access_key],
      key: object_name,
      policy: policy,
      signature: signature,
      success_action_status: 201,
      acl: "public-read" }
  end
  
  
end
