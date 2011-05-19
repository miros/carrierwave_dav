require 'spec_helper'

describe CarrierWave::Dav::Storage do

  let(:uploader) {mock("uploader", :store_path => "http://host/files/file.txt")}
  let(:storage) {described_class.new(uploader, "http://host/files")}
  let(:file) {StringIO.new("some_data")}

  it "allows to store file" do
    stub_any_request
    storage.store!(file)

    a_request(:mkcol, "http://host/files/").should have_been_made
    a_request(:put, "http://host/files/file.txt").with(:body => "some_data").should have_been_made
  end

  it "allows to retrieve file" do
    uploader.should_receive(:store_path).with("identifier") {"http://host/files/file.txt"}

    dav_file = storage.retrieve!("identifier")
    dav_file.should be_instance_of(CarrierWave::Dav::File)
  end

end
