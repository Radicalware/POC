# -*- coding: binary -*-

# note: Because I loose my class stats every enoder iteration, I will need to manage
# the stack outside of that class (so being here). Say I made it so for every push
# there is a pop and vice-versa. That would mean that if you had 10 iterations, you
# could get 10 pops (one per iteration with no subsequent push because it didn't
# randomly draw) and watch your shellcode crash. This way if there is a pop, I could
# let the new class know that we can't have another pop, we need a push, etc.

# There is no stack special handling now, but there will be in future updates.
# I still decided to add to this msf file because it works better for
# displaying your encoder arguments (so it doesn't repeate every iteration)

require 'msf/core/payload/apk'
require 'active_support/core_ext/numeric/bytes'
module Msf

  class PayloadGeneratorError < StandardError
  end

  class EncoderSpaceViolation < PayloadGeneratorError
  end

  class PayloadSpaceViolation < PayloadGeneratorError
  end

  class IncompatibleArch < PayloadGeneratorError
  end

  class IncompatibleEndianess < PayloadGeneratorError
  end

  class IncompatiblePlatform < PayloadGeneratorError
  end

  class InvalidFormat < PayloadGeneratorError
  end

  class PayloadGenerator

    # @!attribute  add_code
    #   @return [String] The path to a shellcode file to execute in a separate thread
    attr_accessor :add_code
    # @!attribute  arch
    #   @return [String] The CPU architecture to build the payload for
    attr_accessor :arch
    # @!attribute  badchars
    #   @return [String] The bad characters that can't be in the payload
    attr_accessor :badchars
    # @!attribute  cli
    #   @return [Boolean] Whether this is being run by a CLI script
    attr_accessor :cli
    # @!attribute  datastore
    #   @return [Hash] The datastore to apply to the payload module
    attr_accessor :datastore
    # @!attribute  encoder
    #   @return [String] The encoder(s) you want applied to the payload
    attr_accessor :encoder
    # @!attribute  format
    #   @return [String] The format you want the payload returned in
    attr_accessor :format
    # @!attribute  framework
    #   @return [Msf::Framework] The framework instance to use for generation
    attr_accessor :framework
    # @!attribute  iterations
    #   @return [Integer] The number of iterations to run the encoder
    attr_accessor :iterations
    # @!attribute  keep
    #   @return [Boolean] Whether or not to preserve the original functionality of the template
    attr_accessor :keep
    # @!attribute  nops
    #   @return [Integer] The size in bytes of NOP sled to prepend the payload with
    attr_accessor :nops
    # @!attribute  payload
    #   @return [String] The refname of the payload to generate
    attr_accessor :payload
    # @!attribute  platform
    #   @return [String] The platform to build the payload for
    attr_accessor :platform
    # @!attribute  smallest
    #   @return [Boolean] Whether or not to find the smallest possible output
    attr_accessor :smallest
    # @!attribute  space
    #   @return [Integer] The maximum size in bytes of the payload
    attr_accessor :space
    # @!attribute  encoder_space
    #   @return [Integer] The maximum size in bytes of the encoded payload
    attr_accessor :encoder_space
    # @!attribute  stdin
    #   @return [String] The raw bytes of a payload taken from STDIN
    attr_accessor :stdin
    # @!attribute  template
    #   @return [String] The path to an executable template to use
    attr_accessor :template
    # @!attribute  var_name
    #   @return [String] The custom variable string for certain output formats
    attr_accessor :var_name


    # @param opts [Hash] The options hash
    # @option opts [String] :payload (see #payload)
    # @option opts [String] :format (see #format)
    # @option opts [String] :encoder (see #encoder)
    # @option opts [Integer] :iterations (see #iterations)
    # @option opts [String] :arch (see #arch)
    # @option opts [String] :platform (see #platform)
    # @option opts [String] :badchars (see #badchars)
    # @option opts [String] :template (see #template)
    # @option opts [Integer] :space (see #space)
    # @option opts [Integer] :encoder_space (see #encoder_space)
    # @option opts [Integer] :nops (see #nops)
    # @option opts [String] :add_code (see #add_code)
    # @option opts [Boolean] :keep (see #keep)
    # @option opts [Hash] :datastore (see #datastore)
    # @option opts [Msf::Framework] :framework (see #framework)
    # @option opts [Boolean] :cli (see #cli)
    # @option opts [Boolean] :smallest (see #smallest)
    # @raise [KeyError] if framework is not provided in the options hash
    def initialize(opts={})
      @add_code   = opts.fetch(:add_code, '')
      @arch       = opts.fetch(:arch, '')
      @badchars   = opts.fetch(:badchars, '')
      @cli        = opts.fetch(:cli, false)
      @datastore  = opts.fetch(:datastore, {})
      @encoder    = opts.fetch(:encoder, '')
      @format     = opts.fetch(:format, 'raw')
      @iterations = opts.fetch(:iterations, 1)
      @keep       = opts.fetch(:keep, false)
      @nops       = opts.fetch(:nops, 0)
      @payload    = opts.fetch(:payload, '')
      @platform   = opts.fetch(:platform, '')
      @space      = opts.fetch(:space, 1.gigabyte)
      @stdin      = opts.fetch(:stdin, nil)
      @template   = opts.fetch(:template, '')
      @var_name   = opts.fetch(:var_name, 'buf')
      @smallest   = opts.fetch(:smallest, false)
      @encoder_space = opts.fetch(:encoder_space, @space)

      @framework  = opts.fetch(:framework)

      raise ArgumentError, "Invalid Payload Selected" unless payload_is_valid?
      raise ArgumentError, "Invalid Format Selected" unless format_is_valid?

      # In smallest mode, override the payload @space & @encoder_space settings
      if @smallest
        @space = 0
        @encoder_space = 1.gigabyte
      end

    end

    # This method takes the shellcode generated so far and adds shellcode from
    # a supplied file. The added shellcode is executed in a separate thread
    # from the main payload.
    # @param shellcode [String] The shellcode to add to
    # @return [String] the combined shellcode which executes the added code in a separate thread
    def add_shellcode(shellcode)
      if add_code.present? and platform_list.platforms.include? Msf::Module::Platform::Windows and arch == ARCH_X86
        cli_print "Adding shellcode from #{add_code} to the payload"
        shellcode_file = File.open(add_code)
        shellcode_file.binmode
        added_code = shellcode_file.read
        shellcode_file.close
        shellcode = ::Msf::Util::EXE.win32_rwx_exec_thread(shellcode,0,'end')
        shellcode << added_code
      else
        shellcode.dup
      end
    end

    # This method takes a payload module and tries to reconcile a chosen
    # arch with the arches supported by the module.
    # @param mod [Msf::Payload] The module class to choose an arch for
    # @return [String] String form of the Arch if a valid arch found
    # @return [Nil] if no valid arch found
    def choose_arch(mod)
      if arch.blank?
        @arch = mod.arch.first
        cli_print "No Arch selected, selecting Arch: #{arch} from the payload"
        datastore['ARCH'] = arch if mod.kind_of?(Msf::Payload::Generic)
        return mod.arch.first
      elsif mod.arch.include? arch
        datastore['ARCH'] = arch if mod.kind_of?(Msf::Payload::Generic)
        return arch
      else
        return nil
      end
    end

    # This method takes a payload module and tries to reconcile a chosen
    # platform with the platforms supported by the module.
    # @param mod [Msf::Payload] The module class to choose a platform for
    # @return [Msf::Module::PlatformList] The selected platform list
    def choose_platform(mod)
      # By default, platform_list will at least return Msf::Module::Platform
      # if there is absolutely no pre-configured platform info at all
      chosen_platform = platform_list

      if chosen_platform.platforms.empty?
        chosen_platform = mod.platform
        cli_print "No platform was selected, choosing #{chosen_platform.platforms.first} from the payload"
        @platform = mod.platform.platforms.first.to_s.split("::").last
      elsif (chosen_platform & mod.platform).empty?
        chosen_platform = Msf::Module::PlatformList.new
      end

      begin
        platform_object = Msf::Module::Platform.find_platform(platform)
      rescue ArgumentError
        platform_object = nil
      end

      if mod.kind_of?(Msf::Payload::Generic) && mod.send(:module_info)['Platform'].empty? && platform_object
        datastore['PLATFORM'] = platform
      end

      chosen_platform
    end

    def multiple_encode_payload(shellcode)
      encoder_str = encoder[1..-1]
      encoder_str.scan(/([^:, ]+):?([^,]+)?/).map do |encoder_opt|
        @iterations = (encoder_opt[1] || 1).to_i
        @iterations = 1 if iterations < 1

        encoder_mod = framework.encoders.create(encoder_opt[0])
        encoder_mod.datastore.import_options_from_hash(datastore)
        shellcode = run_encoder(encoder_mod, shellcode)
      end
      shellcode
    end

    # This method takes the shellcode generated so far and iterates through
    # the chosen or compatible encoders. It attempts to encode the payload
    # with each encoder until it finds one that works.
    # @param shellcode [String] The shellcode to encode
    # @return [String] The encoded shellcode
    def encode_payload(shellcode)
      shellcode = shellcode.dup
      encoder_list = get_encoders
      if encoder_list.empty?
        cli_print "No encoder or badchars specified, outputting raw payload"
        return shellcode
      end

      results = {}

      cli_print "Found #{encoder_list.count} compatible encoders"
      encoder_list.each do |encoder_mod|
        cli_print "Attempting to encode payload with #{iterations} iterations of #{encoder_mod.refname}"
        begin
          encoder_mod.available_space = @encoder_space unless @smallest
          results[encoder_mod.refname] = run_encoder(encoder_mod, shellcode.dup)
          break unless @smallest
        rescue ::Msf::EncoderSpaceViolation => e
          cli_print "#{encoder_mod.refname} failed with #{e.message}"
          next
        rescue ::Msf::EncodingError => e
          cli_print "#{encoder_mod.refname} failed with #{e.message}"
          next
        end
      end

      if results.keys.length == 0
        raise ::Msf::EncodingError, "No Encoder Succeeded"
      end

      # Return the shortest encoding of the payload
      chosen_encoder = results.keys.sort{|a,b| results[a].length <=> results[b].length}.first
      cli_print "#{chosen_encoder} chosen with final size #{results[chosen_encoder].length}"

      results[chosen_encoder]
    end

    # This returns a hash for the exe format generation of payloads
    # @return [Hash] The hash needed for generating an executable format
    def exe_options
      opts = { inject: keep }
      unless template.blank?
        opts[:template_path] = File.dirname(template)
        opts[:template]      = File.basename(template)
      end
      opts
    end

    # This method takes the payload shellcode and formats it appropriately based
    # on the selected output format.
    # @param shellcode [String] the processed shellcode to be formatted
    # @return [String] The final formatted form of the payload
    def format_payload(shellcode)
      case format.downcase
        when "js_be"
          if Rex::Arch.endian(arch) != ENDIAN_BIG
            raise IncompatibleEndianess, "Big endian format selected for a non big endian payload"
          else
            ::Msf::Simple::Buffer.transform(shellcode, format, @var_name)
          end
        when *::Msf::Simple::Buffer.transform_formats
          ::Msf::Simple::Buffer.transform(shellcode, format, @var_name)
        when *::Msf::Util::EXE.to_executable_fmt_formats
          ::Msf::Util::EXE.to_executable_fmt(framework, arch, platform_list, shellcode, format, exe_options)
        else
          raise InvalidFormat, "you have selected an invalid payload format"
      end
    end

    # This method generates Java payloads which are a special case.
    # They can be generated in raw or war formats, which respectively
    # produce a JAR or WAR file for the java payload.
    # @return [String] Java payload as a JAR or WAR file
    def generate_java_payload
      payload_module = framework.payloads.create(payload)
      payload_module.datastore.merge!(datastore)
      case format
      when "raw", "jar"
        if payload_module.respond_to? :generate_jar
          payload_module.generate_jar.pack
        else
          payload_module.generate
        end
      when "war"
        if payload_module.respond_to? :generate_war
          payload_module.generate_war.pack
        else
          raise InvalidFormat, "#{payload} is not a Java payload"
        end
      when "axis2"
        if payload_module.respond_to? :generate_axis2
          payload_module.generate_axis2.pack
        else
          raise InvalidFormat, "#{payload} is not a Java payload"
        end
      else
        raise InvalidFormat, "#{format} is not a valid format for Java payloads"
      end
    end

    # This method is a wrapper around all of the other methods. It calls the correct
    # methods in order based on the supplied options and returns the finished payload.
    # @return [String] A string containing the bytes of the payload in the format selected
    def generate_payload
      if platform == "java" or arch == "java" or payload.start_with? "java/"
        raw_payload = generate_java_payload
        cli_print "Payload size: #{raw_payload.length} bytes"
        gen_payload = raw_payload
      elsif payload.start_with? "android/" and not template.blank?
        cli_print "Using APK template: #{template}"
        apk_backdoor = ::Msf::Payload::Apk.new
        raw_payload = apk_backdoor.backdoor_apk(template, generate_raw_payload)
        cli_print "Payload size: #{raw_payload.length} bytes"
        gen_payload = raw_payload
      else
        raw_payload = generate_raw_payload
        raw_payload = add_shellcode(raw_payload)

        if encoder != nil and encoder.start_with?("@")
          encoded_payload = multiple_encode_payload(raw_payload)
        else
          encoded_payload = encode_payload(raw_payload)
        end
        encoded_payload = prepend_nops(encoded_payload)
        cli_print "Payload size: #{encoded_payload.length} bytes"
        gen_payload = format_payload(encoded_payload)
      end

      if gen_payload.nil?
        raise PayloadGeneratorError, 'The payload could not be generated, check options'
      elsif gen_payload.length > @space and not @smallest
        raise PayloadSpaceViolation, 'The payload exceeds the specified space'
      else
        if format.to_s != 'raw'
          cli_print "Final size of #{format} file: #{gen_payload.length} bytes"
        end

        gen_payload
      end
    end


    # This method generates the raw form of the payload as generated by the payload module itself.
    # @raise [Msf::IncompatiblePlatform] if no platform was selected for a stdin payload
    # @raise [Msf::IncompatibleArch] if no arch was selected for a stdin payload
    # @raise [Msf::IncompatiblePlatform] if the platform is incompatible with the payload
    # @raise [Msf::IncompatibleArch] if the arch is incompatible with the payload
    # @return [String] the raw bytes of the payload to be generated
    def generate_raw_payload
      if payload == 'stdin'
        if arch.blank?
          raise IncompatibleArch, "You must select an arch for a custom payload"
        elsif platform.blank?
          raise IncompatiblePlatform, "You must select a platform for a custom payload"
        end
        stdin
      else
        payload_module = framework.payloads.create(payload)

        chosen_platform = choose_platform(payload_module)
        if chosen_platform.platforms.empty?
          raise IncompatiblePlatform, "The selected platform is incompatible with the payload"
        end

        chosen_arch = choose_arch(payload_module)
        unless chosen_arch
          raise IncompatibleArch, "The selected arch is incompatible with the payload"
        end

        payload_module.generate_simple(
            'Format'      => 'raw',
            'Options'     => datastore,
            'Encoder'     => nil,
            'MaxSize'     => @space,
            'DisableNops' => true
        )
      end
    end

    # This method returns an array of encoders that either match the
    # encoders selected by the user, or match the arch selected.
    # @return [Array<Msf::Encoder>] An array of potential encoders to use
    def get_encoders
      encoders = []
      if encoder.present?
        # Allow comma separated list of encoders so users can choose several
        encoder.split(',').each do |chosen_encoder|
          e = framework.encoders.create(chosen_encoder)
          if e.nil?
            cli_print "Skipping invalid encoder #{chosen_encoder}"
            next
          end
          e.datastore.import_options_from_hash(datastore)
          encoders << e if e
        end
        encoders.sort_by { |my_encoder| my_encoder.rank }.reverse
      elsif !badchars.empty? && !badchars.nil?
        framework.encoders.each_module_ranked('Arch' => [arch], 'Platform' => platform_list) do |name, mod|
          e = framework.encoders.create(name)
          e.datastore.import_options_from_hash(datastore)
          encoders << e if e
        end
        encoders.select{ |my_encoder| my_encoder.rank != ManualRanking }.sort_by { |my_encoder| my_encoder.rank }.reverse
      else
        encoders
      end
    end

    # Returns a PlatformList object based on the platform string given at creation.
    # @return [Msf::Module::PlatformList] It will be empty if no valid platforms found
    def platform_list
      if platform.blank?
        list = Msf::Module::PlatformList.new
      else
        begin
          list = ::Msf::Module::PlatformList.transform(platform)
        rescue
          list = Msf::Module::PlatformList.new
        end
      end
      list
    end

    # This method takes an encoded payload and prepends a NOP Sled to it
    # with a size based on the nops value given to the generator.
    # @param shellcode [String] The shellcode to prepend the NOPs to
    # @return [String] the shellcode with the appropriate nopsled affixed
    def prepend_nops(shellcode)
      if nops > 0
        framework.nops.each_module_ranked('Arch' => [arch]) do |name, mod|
          nop = framework.nops.create(name)
          raw = nop.generate_sled(nops, {'BadChars' => badchars, 'SaveRegisters' => [ 'esp', 'ebp', 'esi', 'edi' ] })
          if raw
            cli_print "Successfully added NOP sled from #{name}"
            return raw + shellcode
          end
        end
      else
        shellcode
      end
    end

    #########################################################################################
    # start of illScrappy def
    def print_scrappy_settings(encoder_module,badchars,iterations)
      $badchars = badchars.unpack("H*").join.scan(/../)
      if (badchars.unpack("H*").join.scan(/../).join(' ')).index('00') == nil
        $nni = true # no nulls indexed
      else
        $nni = false
      end

      $r = Random.new 

      $mult = (encoder_module.datastore['mult']  || '')
      $head = (encoder_module.datastore['head']  || '')
      $foot = (encoder_module.datastore['foot']  || '')
      $jo   =   (encoder_module.datastore['jo']  || '') # junk ops
      $off  =   (encoder_module.datastore['off'] || '') # decoder offset
      $sp   =   (encoder_module.datastore['sp']  || '') # splash only/mix/none
      $sc   =   (encoder_module.datastore['sc']  || '') # splash average
      $sm   =   (encoder_module.datastore['sm']  || '') # splash distance
      $nr   =   (encoder_module.datastore['nr']  || '') # null ratio
      $ric  = ( encoder_module.datastore['ric']  || '') # ruby check
      $silent = (encoder_module.datastore['sl']  || '')
      $help    = (encoder_module.datastore['help'])
      $updates = (encoder_module.datastore['updates'])



        ## DEFAUTS
      if $off  == ''; $off  =    2; else  $off =  $off.to_i;  d_off = false; end
      if $mult == ''; $mult =  0.5; else $mult = $mult.to_f; d_mult = false; end
      if $ric  == ''; $ric  =    8; else  $ric =  $ric.to_i;  d_ric = false; end


      if $nni == true
        if $jo   == ''; $jo   =   25; else   $jo =   $jo.to_i;   d_jo = false; end
        if $head == ''; $head =    2; else $head = $head.to_i; d_head = false; end
        if $sm   == ''; $sm   =  600; else   $sm =   $sm.to_i;   d_sm = false; end
        if $nr   == ''; $nr   =   20; else   $nr =   $nr.to_i;   d_nr = false; end
        if $sc   == ''; $sc   =   37; else   $sc =   $sc.to_i;   d_sc = false; end
        if $sp   == ''; $sp ='mixed'; else                       d_sp = false; end
      else
        if $jo   == ''; $jo   =    4; else   $jo =   $jo.to_i;   d_jo = false; end
        if $head == ''; $head =    2; else $head = $head.to_i; d_head = false; end
                                             $sm = 0
                                             $nr = 0
                                             $sc = 0
                                             $sp = 'never'
      end

      puts iterations
      if iterations > 1; d_it = false; end

      if $badchars.length > 0
        $foot = 0
        d_foot = false
        # I can't regulate bad chars on foot with Additive Feedback
      elsif $foot != ''
        $foot = $foot.to_i
        d_foot = false
      else
        $foot = 1
      end
        
      if $off < 1; $off = 1; end

      $nr = ($r.rand(($nr*$mult).to_i..$nr))


      def color(content,df)
        if df == nil; "\e[31m#{content}\e[0m\e[37m\e[0m" 
        elsif df == 'header';"\e[32m#{content}\e[0m\e[37m\e[0m"
        else; "\e[33m#{content}\e[0m\e[37m\e[0m";end
      end
      
      # 0 = normal
      # 1 = bold
      # 2 = 
      # 3 = italic
      # 4 = underline
      # 5,6 = normal
      # 7 = background
      # 8 = invisible
      # 9 = cross through
      ## sanity checks

      if $sc > 100; cli_print color("splash chance 'sc' must be a number lower than 100.
  If you want it to happen 100% of the junk ops, then use 'sp=only'. Otherwise it won't happen
  100% of the time sense your multiplier will range out your average.
  example: sa=0.25",nil);exit;end
      if $mult > 1; cli_print color("Your multiplier 'mult' must be a floating number lower than 1
  example: mult=0.20",nil);exit;end
      if $sp != 'always' and $sp != 'never' and $sp != 'mixed'; cli_print "splash 'sp' must equal one of the three:
    never|mixed|always"; exit; end

      def white(content);"\e[38m#{content}\e[0m";end 

      if $update or $help
        true == true
      else
        cli_print color("-----------------------------------------------------",'header')
        cli_print color("Settings for...| illScrappy v1.0.0 & r3Evolve v1.0.0",'header')
        cli_print color("-----------------------------------------------------",'header')
        cli_print "Header.........|...head="+color($head,d_head)
        cli_print "Footer.........|...foot="+color($foot,d_foot)
        cli_print "Junk OPs.......|.....jo="+color($jo,d_jo)
        cli_print "Offset.........|....off="+color($off,d_off)
        cli_print "Splash.........|.....sp="+color($sp,d_sp)
        cli_print "Splash chance..|.....sc="+color($sc,d_sc)
        cli_print "Splash Max.....|.....sm="+color($sm,d_sm)
        cli_print "Multiplier.....|...mult="+color($mult,d_mult)
        cli_print "Null Ratio.....|.....nr="+color($nr,d_nr)
        cli_print "Ruby Check.....|....ric="+color($ric,d_ric)
        cli_print "Iterations.....|.....-i "+color(iterations,d_it)
        cli_print color("-----------------------------------------------------",'header')
        cli_print color("illScrappy is a product of Radicalware.net",'header')
        cli_print color("-----------------------------------------------------",'header')
      end
      if $nni == false
        cli_print color("Warning: null-free is NOT advised for Trojans\nUse 'help' for help to learn more about Scrappy",nil)
        cli_print color("-----------------------------------------------------",'header')
      end
      if iterations < 9  
        cli_print color("Warning: The encryption for illScrappy is still weak\nI suggest at least 9 iterations until it's upgraded",nil)
        cli_print color("-----------------------------------------------------",'header')       
      end
      if $nni == true
        $off = $r.rand((($off*$sm)*$mult).to_i..($off*$sm))
      else
        $off = $r.rand(3..14)
      end      
    end


    # end of illScrappy def
    #########################################################################################

    def run_encoder(encoder_module, shellcode)
      # >>>>> illScrappy
      if /illScrappy/.match(encoder_module.refname) != nil
        if (/[0-9]/.match((encoder_module.datastore.to_s).index('SL').to_s)).to_s != ''
          true == true
        else
          print_scrappy_settings(encoder_module,badchars,iterations)
        end
      end
      # <<<<< illScrappy
      iterations.times do |x|
        shellcode = encoder_module.encode(shellcode.dup, badchars, nil, platform_list)
        cli_print "#{encoder_module.refname} succeeded with size #{shellcode.length} (iteration=#{x})"
        if shellcode.length > encoder_space
          raise EncoderSpaceViolation, "encoder has made a buffer that is too big"
        end
      end
      shellcode
    end

    private

    # This method prints output to the console if running in CLI mode
    # @param [String] message The message to print to the console.
    def cli_print(message= '')
      $stderr.puts message if cli
    end

    # This method checks if the Generator's selected format is valid
    # @return [True] if the format is valid
    # @return [False] if the format is not valid
    def format_is_valid?
      formats = (::Msf::Util::EXE.to_executable_fmt_formats + ::Msf::Simple::Buffer.transform_formats).uniq
      formats.include? format.downcase
    end

    # This method checks if the Generator's selected payload is valid
    # @return [True] if the payload is a valid Metasploit Payload
    # @return [False] if the payload is not a valid Metasploit Payload
    def payload_is_valid?
      (framework.payloads.keys + ['stdin']).include? payload
    end

  end
end
