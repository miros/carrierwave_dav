require 'spec_helper'

describe CarrierWave::Dav::File do

  describe "#file_path" do
    it "returns path to file from host root" do
      file = described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore/")
      file.file_path.should == "/appstore/applications/file.txt"
    end
  end

  describe "#dav_host" do
    it "returns correct dav_host when host has port" do
      file = described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore/")
      file.dav_host.should == "http://localhost:1234"
    end

    it "returns dav_host when host has no port" do
      file = described_class.new('http://localhost/appstore/applications/file.txt', "http://localhost/appstore/")
      file.dav_host.should == "http://localhost"
    end
  end

  describe "#path" do
    it "returns full file uri including dav host" do
      file = described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore/")
      file.path.should == 'http://localhost:1234/appstore/applications/file.txt'
    end
  end

  describe "#url" do
    it "returns file url" do
      file = described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore/")
      file.url.should == '/applications/file.txt'
    end
    it "returns correct url when dav path has no trailing slash" do
      file = described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore")
      file.url.should == '/applications/file.txt'
    end
  end

  it "creates connection with appropriate url" do
    CarrierWave::Dav.dav_factory.should_receive(:call).with("http://localhost:1234")
    described_class.new('http://localhost:1234/appstore/applications/file.txt', "http://localhost:1234/appstore/")
  end

  describe "working with files" do
    let(:connection) {mock("connection").as_null_object}
    let(:file) {described_class.new("http://localhost:1234/appstore/some/path/file.txt", "http://localhost:1234/appstore", connection)}

    describe "#read" do
      it "reads file from storage" do
        file_data = mock
        connection.should_receive(:get).with("/appstore/some/path/file.txt") {file_data}
        file.read.should == file_data
      end
    end

    describe "#size" do
      it "returns size of file" do
        connection.should_receive(:get).with("/appstore/some/path/file.txt") {"12345"}
        file.size.should == 5
      end
    end

    describe "#write" do
      it "tries to create folder for file" do
        file.should_receive(:mkpath).with("/appstore/some/path")
        file.write(StringIO.new("data"))
      end
      it "writes file to storage" do
        connection.should_receive(:put_string).with("/appstore/some/path/file.txt", "data")
        file.write(StringIO.new("data"))
      end
    end

    describe "#mkpath" do
      it "creates dirs one-by-one" do
       connection.should_receive(:mkdir).with("/some/").ordered
       connection.should_receive(:mkdir).with("/some/long/").ordered
       connection.should_receive(:mkdir).with("/some/long/path/").ordered
       file.mkpath("/some/long/path")
      end

      it "memorizes created dirs " do
       file.mkpath("/some/long/path")
       file.created_dirs.should == ["/some/", "/some/long/", "/some/long/path/"]
      end

      it "memorizes only dirs that were really created" do
       connection.should_receive(:mkdir).with("/some/").and_raise(Net::HTTPClientException.new(nil, nil))

       file.mkpath("/some/long/path")
       file.created_dirs.should == ["/some/long/", "/some/long/path/"]
      end

      it "ignores EOFError errors" do
       connection.should_receive(:mkdir).with("/some/").and_raise(EOFError)

       file.mkpath("/some/long/path")
       file.created_dirs.should == ["/some/", "/some/long/", "/some/long/path/"]
      end
    end

    describe "#destroy_created_dirs!" do
      it "destroy created dirs in reversed order" do
        file.mkpath("/some/long/path")

        connection.should_receive(:delete).with("/some/long/path/").ordered
        connection.should_receive(:delete).with("/some/long/").ordered
        connection.should_receive(:delete).with("/some/").ordered

        file.destroy_created_dirs!
      end
      context "when min_depth param given" do
        it "deletes only directories with depth >= min_depth" do
          file.mkpath("/some/very/long/path")

          connection.should_receive(:delete).with("/some/very/long/path/").ordered
          connection.should_receive(:delete).with("/some/very/long/").ordered
          connection.should_not_receive(:delete).with("/some/very/")
          connection.should_not_receive(:delete).with("/some/")

          file.destroy_created_dirs!(:min_depth => 3)
        end

      end

    end

    describe "#delete" do
      it "deletes file" do
        connection.should_receive(:delete).with("/appstore/some/path/file.txt")
        file.delete
      end

      it "ignores all errors of file deletion" do
        connection.stub(:delete).and_raise(Exception)
        expect { file.delete }.to_not raise_error
      end
    end
  end

end


