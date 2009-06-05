require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Compile do
  describe "new_from_request" do
    before(:each) do
      @user = User.create!(:token => Digest::MD5.hexdigest('foo'))
    end

    describe "with valid request" do
      before(:each) do
        @compile = Compile.new_from_request(<<-EOS
          <compile>
            <token>#{@user.token}</token>
            <project-id>MyProject</project-id>
            <resources root-resource-path="chapters/main.tex">
              <resource path="chapters/main.tex" modified="2009-03-29T06:00Z">Hello TeX.</resource>
              <resource path="chapters/chapter1.tex" modified="2009-03-29" url="http://www.latexlab.org/getfile/bsoares/23234543543"/>
            </resources>
          </compile>
        EOS
        )
      end

      it "should load the information about the compile" do
        @compile.user.should eql @user
        @compile.project_id.should eql 'MyProject'
        @compile.root_resource_path.should eql 'chapters/main.tex'
      end
    end

    describe "with invalid token" do
      it "should raise a CLSI::InvalidToken error" do
        lambda{
          @compile = Compile.new_from_request(<<-EOS
            <compile>
              <token>#{Digest::MD5.hexdigest('blah')}</token>
              <resources></resources>
            </compile>
          EOS
          )
        }.should raise_error(CLSI::InvalidToken, 'user does not exist')
      end
    end
  end
end
