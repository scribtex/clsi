config = YAML::load(ERB.new(File.read(File.join(RAILS_ROOT, 'config/config.yml'))).result)[Rails.env]

LATEX_CHROOT_DIR  = config['latex_chroot_dir']
LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT = config['latex_compile_dir_relative_to_chroot']
LATEX_COMPILE_DIR = config['latex_compile_dir']
LATEX_COMMAND     = config['latex_command']
PDFLATEX_COMMAND  = config['pdflatex_command']
BIBTEX_COMMAND    = config['bibtex_command']
DVIPDF_COMMAND    = config['dvipdf_command']
DVIPS_COMMAND     = config['dvips_command']
MAKEINDEX_COMMAND = config['makeindex_command']

COMPILE_TIMEOUT = config['compile_timeout']
BIBTEX_TIMEOUT  = config['bibtex_timeout']
DVIPDF_TIMEOUT  = config['dvipdf_timeout']
DVIPS_TIMEOUT   = config['dvips_timeout']

SERVER_PUBLIC_DIR = config['server_public_dir']
HOST = config['host']

CACHE_DIR = config['cache_dir']

PRESERVE_COMPILE_DIRECTORIES = config['preserve_compile_directories'] || false

ExceptionNotifier.exception_recipients = config['exception_notification_recipient'].to_a
