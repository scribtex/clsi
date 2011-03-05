require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Compile do
  describe "validate_compile" do
    before do
      @user = User.create!
      @compile = Compile.new(:token => @user.token)
    end

    it "should raise a CLSI::InvalidToken error if it's token doesn't correspond to a user" do
      @compile.token = Digest::MD5.hexdigest('blah')
      lambda{
        @compile.validate_compile
      }.should raise_error(CLSI::InvalidToken, 'user does not exist')
    end
    
    it "should raise a CLSI::UnknownCompiler error if it has an unknown compiler" do
      @compile.compiler = 'gcc'
      lambda{
        @compile.validate_compile
      }.should raise_error(CLSI::UnknownCompiler, 'gcc is not a valid compiler')
    end

    it "should raise a CLSI::ImpossibleOutputFormat error" do
      @compile.compiler = 'pdflatex'
      @compile.output_format = 'avi'
      lambda{
        @compile.validate_compile
      }.should raise_error(CLSI::ImpossibleOutputFormat, 'pdflatex cannot produce avi output')
    end
  end

  describe "different compilers and output formats" do
    before do
      @compile = Compile.new
      @user = User.create!
      @compile.user = @user
      @compile.root_resource_path = 'main file.tex'
      @compile.resources = []
      @compile.resources << Resource.new(
        'main file.tex', nil,
        '\\documentclass{article} \\begin{document} \\input{chapters/chapter1} \\end{document}', nil,
        @compile
      )
      @compile.resources << Resource.new(
        'chapters/chapter1.tex', nil,
        'Chapter1 Content!', nil,
        @compile
      )
    end
    
    shared_examples_for 'an output format of pdf' do
      it "should return the PDF for access by the client" do
        rel_path = File.join('output', @compile.unique_id, 'output.pdf')
        output_file = @compile.output_files.find{|o| o.path = rel_path}
        output_file.should_not be_nil
        output_file.type.should eql 'pdf'
        output_file.mimetype.should eql 'application/pdf'
        File.exist?(File.join(SERVER_PUBLIC_DIR, rel_path)).should be_true
      end
    end
    
    shared_examples_for 'an output format of dvi' do
      it "should return the DVI for access by the client" do
        rel_path = File.join('output', @compile.unique_id, 'output.dvi')
        output_file = @compile.output_files.find{|o| o.path = rel_path}
        output_file.should_not be_nil
        output_file.type.should eql 'dvi'
        output_file.mimetype.should eql 'application/x-dvi'
        File.exist?(File.join(SERVER_PUBLIC_DIR, rel_path)).should be_true
      end
    end

    shared_examples_for 'an output format of ps' do
      it "should return the PostScript file for access by the client" do
        rel_path = File.join('output', @compile.unique_id, 'output.ps')
        output_file = @compile.output_files.find{|o| o.path = rel_path}
        output_file.should_not be_nil
        output_file.type.should eql 'ps'
        output_file.mimetype.should eql 'application/postscript'
        File.exist?(File.join(SERVER_PUBLIC_DIR, rel_path)).should be_true
      end
    end
    
    shared_examples_for 'a successful compile' do
      it "should return the log for access by the client" do
        rel_path = File.join('output', @compile.unique_id, 'output.log')
        @compile.log_files.should include(OutputFile.new(:path => rel_path))
        File.exist?(File.join(SERVER_PUBLIC_DIR, rel_path)).should be_true
      end
      
      it "should remove the compile directory" do
        File.exist?(@compile.compile_directory).should be_false
      end
      
      it 'should set the compile status to success' do
        @compile.status.should eql :success
      end
      
      it 'should write the xml response to disk for future reference' do
        response_path = File.join(SERVER_PUBLIC_DIR, 'output', @compile.unique_id, 'response.xml')
        File.exist?(response_path).should be_true
        File.read(response_path).should eql @compile.to_xml
      end
    end
    
    describe 'with pdflatex compiler and output format of pdf' do
      before do
        @compile.compile
      end
      
      it_should_behave_like 'an output format of pdf'
      it_should_behave_like 'a successful compile'
    end

    describe 'with latex compiler and output format of dvi' do
      before do
        @compile.compiler = 'latex'
        @compile.output_format = 'dvi'
        @compile.compile
      end

      it_should_behave_like 'an output format of dvi'
      it_should_behave_like 'a successful compile'
    end
    
    describe 'with latex compiled and output format of pdf' do
      before do
        @compile.compiler = 'latex'
        @compile.output_format = 'pdf'
        @compile.compile
      end

      it_should_behave_like 'an output format of pdf'
      it_should_behave_like 'a successful compile'
    end

    describe 'with latex compiled and output format of ps' do
      before do
        @compile.compiler = 'latex'
        @compile.output_format = 'ps'
        @compile.compile
      end

      it_should_behave_like 'an output format of ps'
      it_should_behave_like 'a successful compile'
    end
  end

  describe "bibtex" do
    before do
      @compile = Compile.new
      @user = User.create!
      @compile.user = @user
      @compile.root_resource_path = 'main.tex'
      @compile.resources = []
      @compile.resources << Resource.new(
        'bibliography.bib', nil,
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'bibliography.bib')), nil,
        @compile
      )
    end
    
    it "should not run when no citations or references to the bibliography are made" do
      @content = <<-EOS
        \\documentclass{article}
        \\begin{document}
        Hello World.
        \\end{document}
      EOS
      @compile.resources << Resource.new(
        'main.tex', nil,
        @content, nil,
        @compile
      )
      @compile.should_not_receive(:run_bibtex)
      @compile.compile
    end
    
    it "should run when citations are made" do
      @content = <<-EOS
        \\documentclass{article}
        \\begin{document}
        Hello World \\cite{small}.
        \\end{document}
      EOS
      @compile.resources << Resource.new(
        'main.tex', nil,
        @content, nil,
        @compile
      )
      @compile.should_receive(:run_bibtex)
      @compile.compile
    end
    
    it "should run when a reference to biliography is made" do
      @content = <<-EOS
        \\documentclass{article}
        \\begin{document}
        Hello World.
        \\bibliography{bibliography}
        \\end{document}
      EOS
      @compile.resources << Resource.new(
        'main.tex', nil,
        @content, nil,
        @compile
      )
      @compile.should_receive(:run_bibtex)
      @compile.compile
    end
    
    it "should run when a reference to a biliography style is made" do
      @content = <<-EOS
        \\documentclass{article}
        \\begin{document}
        Hello World.
        \\bibliographystyle{plain}
        \\end{document}
      EOS
      @compile.resources << Resource.new(
        'main.tex', nil,
        @content, nil,
        @compile
      )
      @compile.should_receive(:run_bibtex)
      @compile.compile
    end
  end

  describe 'makeindex' do
    before do
      @compile = Compile.new
      @user = User.create!
      @compile.user = @user
      @compile.root_resource_path = 'main.tex'
      @compile.resources = []
    end
    
    describe 'with a document containing an index' do
      before do
        @content = <<-EOS
          \\documentclass{article}
          \\usepackage{makeidx}
          \\makeindex
          \\begin{document}
          Hello World. \\index{Index Entry}
          \\printindex
          \\end{document}
        EOS
        @compile.resources << Resource.new(
          'main.tex', nil,
          @content, nil,
          @compile
        )
      end
      
      it 'should run makeindex' do
        @compile.should_receive(:run_makeindex)
        @compile.compile
      end
      
      it 'should run successfully and create an index in the document' do
        @compile.compile
        read_pdf(@compile.output_files.first.path_on_disk).should include 'Index Entry'
      end
    end
    
    it 'should not run makeindex if the document does not contain an index' do
      @content = <<-EOS
        \\documentclass{article}
        \\begin{document}
        Hello World.
        \\end{document}
      EOS
      @compile.resources << Resource.new(
        'main.tex', nil,
        @content, nil,
        @compile
      )
      @compile.should_not_receive(:run_makeindex)
      @compile.compile      
    end
  end

  describe 'references' do
    before do
      Compile.send(:public, :run_compiler)
      class Compile
        alias :unspecced_run_compiler :run_compiler
      end
      @compile = Compile.new
      @user = User.create!
      @compile.user = @user
      @compile.root_resource_path = 'main.tex'
      @compile.resources = []
      @compile.resources << Resource.new(
        'bibliography.bib', nil,
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'bibliography.bib')), nil,
        @compile
      )
    end
    
    describe 'document with no references' do
      before do
        @content = <<-EOS
          \\documentclass{article}
          \\begin{document}
          Hello World.
          \\end{document}
        EOS
        @compile.resources << Resource.new(
          'main.tex', nil,
          @content, nil,
          @compile
        )
      end
      
      it 'should only run LaTeX once' do
        @compile.should_receive(:run_compiler) {
          @compile.unspecced_run_compiler
        }.once
        @compile.compile
      end
    end
    
    describe 'document with references' do
      before do
        @content = <<-EOS
          \\documentclass{article}
          \\begin{document}
          Hello World. \\label{example}
          \\ref{example}
          \\end{document}
        EOS
        @compile.resources << Resource.new(
          'main.tex', nil,
          @content, nil,
          @compile
        )
      end
      
      it 'should run latex multiple times' do
        @compile.should_receive(:run_compiler) {
          @compile.unspecced_run_compiler
        }.twice
        @compile.compile
      end
    end
    
    describe 'document with bibtex and references' do
      before do
        @content = <<-EOS
          \\documentclass{article}
          \\begin{document}
          Hello World. \\cite{small}
          \\bibliographystyle{plain}
          \\bibliography{bibliography}
          \\end{document}
        EOS
        @compile.resources << Resource.new(
          'main.tex', nil,
          @content, nil,
          @compile
        )
      end
      it 'should run latex before bibtex and multiple times after' do
        @compile.should_receive(:run_compiler) {
          @compile.unspecced_run_compiler
        }.exactly(3).times
        @compile.compile
      end
    end
  end

  describe "unsuccessful compile" do
    before do
      @compile = Compile.new
      @user = User.create!
      @compile.user = @user
      @compile.root_resource_path = 'main.tex'
      @compile.resources = []
      @compile.resources << Resource.new(
        'main.tex', nil,
        '\\begin{document}', nil,
        @compile
      )
      @compile.compile
    end
    
    it 'should set its status to failure and report errors' do
      @compile.status.should eql :failure
      @compile.error_type.should eql 'NoOutputProduced'
      @compile.error_message.should eql 'no compiled documents were produced'
    end

    it "should return the log for access by the client" do
      rel_log_path = File.join('output', @compile.unique_id, 'output.log')
      @compile.log_files.should include(OutputFile.new(:path => rel_log_path))
      File.exist?(File.join(SERVER_PUBLIC_DIR, rel_log_path)).should be_true
    end
      
    it 'should write the xml response to disk for future reference' do
      response_path = File.join(SERVER_PUBLIC_DIR, 'output', @compile.unique_id, 'response.xml')
      File.exist?(response_path).should be_true
      File.read(response_path).should eql @compile.to_xml
    end
  end
  
  describe 'to_json' do
    before do
      @compile = Compile.new
    end
    
    it 'should output json' do
      @compile.instance_variable_set('@status', :success)
      @compile.instance_variable_set('@unique_id', '1234567890')
      @compile.output_files << OutputFile.new(:path => 'test.pdf')
      @compile.log_files    << OutputFile.new(:path => 'test.log')
      
      JSON.parse(@compile.to_json).should eql({
        'compile' => {
          'compile_id' => @compile.unique_id,
          'status'     => 'success',
          'output_files' => @compile.output_files.collect{|of| {
            'url'      => of.url,
            'mimetype' => of.mimetype,
            'type'     => of.type
          }},
          'logs' => @compile.log_files.collect{|lf| {
            'url'      => lf.url,
            'mimetype' => lf.mimetype,
            'type'     => lf.type
          }}
        }
      })
    end
    
    it 'should not include output files section if none produced' do
      @compile.instance_variable_set('@status', :success)
      @compile.instance_variable_set('@unique_id', '1234567890')
      @compile.log_files    << OutputFile.new(:path => 'test.log')
      
      JSON.parse(@compile.to_json).should eql({
        'compile' => {
          'compile_id' => @compile.unique_id,
          'status'     => 'success',
          'logs' => @compile.log_files.collect{|lf| {
            'url'      => lf.url,
            'mimetype' => lf.mimetype,
            'type'     => lf.type
          }}
        }
      })
    end
    
    it 'should not include log files section' do
      @compile.instance_variable_set('@status', :unprocessed)
      @compile.instance_variable_set('@unique_id', '1234567890')
      
      JSON.parse(@compile.to_json).should eql({
        'compile' => {
          'compile_id' => @compile.unique_id,
          'status'     => 'unprocessed'
        }
      })
    end
    
    it 'should include an error section if compile failed' do
      @compile.instance_variable_set('@status', :failure)
      @compile.instance_variable_set('@unique_id', '1234567890')
      @compile.instance_variable_set('@error_type', 'ErrorType')
      @compile.instance_variable_set('@error_message', 'Error Message')
      
      JSON.parse(@compile.to_json).should eql({
        'compile' => {
          'compile_id' => @compile.unique_id,
          'status'     => 'failure',
          'error'      => {
            'message' => 'Error Message',
            'type'    => 'ErrorType'
          }
        }
      })
    end
  end

  describe "timedout compile" do
    it "should timeout" do
      @compile = Compile.new
      lambda {
        @compile.send('run_with_timeout', "sh " + File.expand_path(RAILS_ROOT + '/spec/fixtures/sleep.sh'), 0.1) 
      }.should raise_error CLSI::Timeout
      %x[ps -a -x].should_not include('/bin/sleep') # lets hope no one else has sleep running!
    end
  end
end
