#!/usr/bin/env ruby
# rm -rf ./test; rm ./tmp; msfvenom -p linux/x64/e257 --platform linux -a x86_64 -f c -e x64/mystique -b '\x00' | Rmutate -s -pp -bc -linux -df ./test test && ./test/shellcode-test

# r3Evolve v1

## r3Evolve.rb is a Radicalware product programmed by Scourge
## r3Evolve.rb is under the GPLv3 Licence
## This can be a stand-alone module to build polymorphic shellcode
## It was first designed to be used with Scrappy, an MSF encoder

# Updates none: this is the original release v1.0.0

begin

module R3EVOLVE
	module Functional
		def con(optc)
			begin
				if $ac != 'x64'
					Metasm::Shellcode.assemble(Metasm::Ia32.new, optc).encode_string
				else
					Metasm::Shellcode.assemble(Metasm::X64.new, optc).encode_string
				end
			rescue
				if $silent
					true == true
				else
					puts '---failed opCode ---'
					puts optc+'  '
					puts '---failed opCode---'
					quit()
				end
			end
		end
		def hex(bytecode)
			bytecode.unpack("H*").join('')
		end
		def reg_size(hex_str)
			if hex_str.length%2 != 0
				hex_str = '0'+hex_str
			end
			stripped_hex = hex_str.sub /^0x/,''
			hex_leng = stripped_hex.length/2

			# return the reg_size for the data size found in the $reg matrix
			if hex_leng > 8
				size =  100
			elsif hex_leng > 4  # rax
				size =  0 
			elsif hex_leng > 2  # ebx
				size =  1
			elsif hex_leng == 2 # ax
				size =  2
			elsif hex_leng == 1 # al
				size =  3
			end
			if $ac != 'x64'
				size -= 1 # rax = 0 in 64, eax = 0 in 32
			end

			return size
			def even_hex(hexer)
				hexer.sub! /^0x/,''
				if hexer.length%2 != 0
					hexer = '0'+hexer
				end;return hexer
			end
		end

		def get_bytes(reg_div)
			def rand_byte(reg_div)
				r64, r32, r16, r8 = reg_div
				def choose_reg_size(reg_div)
					lowest_dis = 100
					count = 3
					closest_num = 100
					while count > 0
						reg_div.each do |x|
							if lowest_dis > ((x-$r.rand(0..100)).abs)
								lowest_dis = ((x-$r.rand(0..100)).abs)
								closest_num = x
								count = 3
							end
							count -= 1
						end
					end

					sm = 1+$r.rand()
					# $r.rand() always returns a long floating decimal
					return closest_num,sm
				end

				closest_num,sm = choose_reg_size(reg_div)

				if r64 == closest_num #and $ac == 'x64'
					hd = (($r.rand(4294967296..18446744073709551615)*sm-18446744073709551615).abs).to_i.to_s(16)

				elsif r32 == closest_num
					hd = (($r.rand(65536..4294967295)*sm-4294967295).abs).to_i.to_s(16)

				elsif r16 == closest_num
					hd = (($r.rand(256..65535)*sm-65535).abs).to_i.to_s(16)

				elsif r8 == closest_num
					hd = (($r.rand(0..255)*sm-255).abs).to_i.to_s(16)

				else
					quit()
				end

				if hd.length%2 != 0
					hd = '0'+hd
				end
				return hd
			end
			r64, r32, r16, r8 = reg_div

			hd = rand_byte(reg_div)
			# hd is your hex data such as 0x41 or 0x41424344
			hd_bytes = hd.scan(/../)
			restart = true
			while restart == true
				restart = false
				$badchars.each do |x|
					hd_bytes.each do |y|
						if x == y
							hd = rand_byte(reg_div)
							hd_bytes = hd.scan(/../)
							restart = true
						end
					end

				end
			end
			return ('0x'+hd)
		end # get_bytes
	end

	module Clear_Reg
		def full_clearance(reg1, reg2, reg3)
			means = $r.rand(0..1)
			#puts means
			if    means == 0
				return ("xor  #{reg1}, #{reg2}")
			#elsif means == 1
			#	return ("andn #{reg1}, #{reg2}, #{reg3}")
			elsif means == 1
				return ("sub  #{reg1}, #{reg2}")
			end
		end
		def byte_clearance(reg1, reg2, reg3) # clears downt one byte
			means = $r.rand(0..2)
			if    means == 0
				data = ($r.rand(248..255)).to_s
				return ("shr #{reg1}, #{data}")
			elsif means == 1
				data = ($r.rand(0..255)).to_s
				return ("lea #{reg1}, \[#{data}\] ")
			end			
		end
		def null_clearance(reg1, reg2, reg3)
			means = $r.rand(0..2)
			if    means == 0
				return ("mov #{reg1}, 0x00")
			elsif means == 1
				return ("lea #{reg1}, \[0x00\] ")
			elsif means == 2
				return ("and #{reg1}, 0x00")
			end			
		end
		def dub_step(reg1, reg2, reg3) # full clearance but takes more than one step
			# !!!!!!!!!! fix this by adding the pre-req step for means 0 and 1
			means = ($r.rand(0..2)).to_s
			if    means == 0
				# reg must have at least two nibbles
				return ("shl  #{reg1}, 0xff")		
			elsif means == 1
				# data must be at least one byte shy from filling the register
				return ("shr  #{reg1}, 0xff")
			end
		end
		def choose_clearance(reg1, reg2, reg3, extra)
			#puts reg1;puts reg2; puts reg3; puts extra;puts '----'
			means = 0
			if    means == 0 or extra == 'full'
				return full_clearance(reg1, reg2, reg3)
			elsif means == 1			
				return byte_clearance(reg1, reg2, reg3)
			elsif means == 2
				return null_clearance(reg1, reg2, reg3) 
			end
		end
	end # Clear_Reg
	## ---------------------------------------------------------------------------
	module Stacker
		def pushit(reg1); return ("push #{reg1}"); end 
		def popit(reg1); return ("pop  #{reg1}"); end
		## usage of add/sub stack will come in Scrappy v2
		def add_stack(reg1, reg2); return ("add  #{reg1}, #{reg2}"); end
		def sub_stack(reg1, reg2); return ("sub  #{reg1}, #{reg2}"); end
	end
	## ---------------------------------------------------------------------------
	module JMPs
		## new jump techniques will come in Scrappy v2
		## To use this effectively, I will need to make a new class called dub-step
		def jmp_short(distance)
			return "\xeb"+([distance.to_i].pack("Q*").gsub /\000*$/,'')
			# returns little endian hex (ready for shellcode)
		end
		def jmp_long(distance)
			return "\xe9"+([distance.to_i].pack("Q*").gsub /\000*$/,'')
		end
		def je(distance)
			return ""
		end
		def jne(distance)
			return ""
		end
		def jz(distance)
		end
		def jnz(distance)
		end
		def call_it(distance)
			return ""
		end
		def nasm_loop(distance)
			return "\xe2"# + 255 - (bytes to return to + 1)
		end
	end # JMPs
	## ---------------------------------------------------------------------------

	module MOVs
		def  mov(reg1, reg2);return ("mov #{reg1}, #{reg2}");end
		def  lea(reg1, reg2);return ("lea #{reg1}, \[#{reg2}\]");end
		def xchg(reg1, reg2);return ("xchg #{reg1}, #{reg2}");end
	end
	## ---------------------------------------------------------------------------

	module Bitwise
		def ptr_xor_1(reg1, reg2); return ("xor \[#{reg1}\], #{reg2}");end
		def ptr_add_2(reg1, reg2); return ("add #{reg1}, \[#{reg2}\]");end
		def inc(reg1);      return ("inc #{reg1}");end
		def dec(reg1);      return ("dec #{reg1}");end
		def mul(reg1);      return ("mul #{reg1}");end
		def div(reg1);      return ("div #{reg1}");end
		def xor(reg1, reg2);return ("xor #{reg1}, #{reg2}");end
		def add(reg1, reg2);return ("add #{reg1}, #{reg2}");end
		def subit(reg1, reg2);return ("sub #{reg1}, #{reg2}");end
	end
	## ---------------------------------------------------------------------------

	module Compare
		## new cmp will come later like xor r14, r15 to see if you get a ZF, if so . . . jz
		def   cmp(reg1, reg2);return ("cmp  #{reg1}, #{reg2}");end
		def btest(reg1, reg2);return ("test #{reg1}, #{reg2}");end
		## test apposed to cmp is one of the many things that will come in Scrappy v2
		def choose_compare(reg1, reg2)
			means = 0
			if means == 0
				return cmp(reg1, reg2)
			end
		end
	end
	## #################################################################################	

	class Polymorph
		include Clear_Reg
		include JMPs
		include Stacker
		include MOVs
		include Bitwise
		include Compare
		include Functional

		attr_accessor :junk, :junkyard, :ss, :looper, :key, :code
		attr_accessor :reg_div, :reserved, :stack_hold, :stack_count
		attr_accessor :acthash
		# when making this a superclass you must always check
		# 1. Polymorph.new(all args present)
		# 2. attr_accessor includes all args
		# 3. initialize includes all args
		# 4. the subclass "super" must include all args
		# 5. the defs that print the args must be all present that are @@ vars

		# includes all args    : new, attr_accessor, initialize, subclass
		# includes only @@ args: defs that print args in superclass

		def initialize(junk,junkyard,ss,looper,key,code,reg_div,reserved,stack_hold,stack_count,acthash)
			@@junk     = junk
			@@junkyard = []
			@@ss       = ss
			@@looper   = looper
			@@key      = key
			@@code     = code

			r64 = 0; r32 = 0; r16 = 0; r8 = 0
			reg_div = [r64, r32, r16, r8]
			while reg_div.count(reg_div.max_by { |i| reg_div.count(i) }) > 1
				# while prevents having two registers with the same num
				def skew(lowest_available,count)
					def curve (lowest_available)

						mid = ((100 - lowest_available)/1.5).to_i
						div = $r.rand(0..mid)
						div += lowest_available
						return div
					end

					if count == 1
						div = 100
					else
						div = curve(lowest_available)
					end
					lowest_available = div
					return div,lowest_available
				end

				lowest_available = 0
				count = 4
				used = []
				while count > 0
					sreg=$r.rand(0..3)
					if sreg == 0 and used.count(0)==1
						r64,lowest_available = skew(lowest_available,count)
						count -= 1
					elsif sreg == 1 and used.count(1)==1
						r32,lowest_available = skew(lowest_available,count)
						count-=1
					elsif sreg == 2 and used.count(2)==1
						r16,lowest_available = skew(lowest_available,count)
						count-=1    
					elsif sreg == 3 and used.count(3)==1
						r8,lowest_available = skew(lowest_available,count)
						count-=1                    
					end
					used.push(sreg)
				end
				reg_div = [r64, r32, r16, r8]
			end

			@reg_div=reg_div

			@@reserved=reserved
			# Stack modding has been omitted for Scrappy v1
			# Stack handling and junk pointers will come later
			@@stack_hold=stack_hold
			@@stack_count=stack_count


			## The skew/curve method for qword, dword, word byte is more powerful than this;
			## however, this bitwise function skew method is much more managable. 
			acthash = {
				'mov'  => [], 
				'lea'  => [], 
				'inc'  => [], 
				'dec'  => [],
				'push' => [], 
				'pop'  => [],
				'add'  => [], 
				'sub'  => [],
				'mul'  => [],
				'div'  => [],
				'xchg' => [],
				'xor'  => [],
			}

			reserve = 30 # for mov/lea
			pot = 100-reserve

			split_pot = pot/acthash.length

			averaged = []

			until averaged.length == acthash.length
				act = (acthash.keys[$r.rand(0..(acthash.length-1))])
				while averaged.index(act); act = (acthash.keys[$r.rand(0..(acthash.length-1))]); end
				averaged.push(act)
				reloop = 2
				while reloop > 0
					acthash[act].push($r.rand(0..split_pot).to_i)
					reloop -= 1
				end
			end


			current_total = 0
			acthash.each do |x,y|
				sum = 0
				y.each {|v| sum += v}
				avg = sum / y.length
				acthash[x] = avg
				current_total += avg
			end

			while current_total != pot
				acthash.each do |x,y|
					if $r.rand(0..5) == 1
						acthash[x] = (y+1)
						current_total += 1
					end
					if current_total == pot; break; end
				end
			end

			# inc thes functions sense they should be hit more
			acthash['mov'] += (reserve/2).to_i # div 2 sense we are inc twice
			acthash['lea'] += (reserve/2).to_i

			# space out each num so it goes inc from the last one
			# say  mov = 10, lea = 20, xor = 5 in that order
			# next mov = 10, lea = 30, xor = 35
			# so if the die roles on 25, lea wins sense it is between 10 and 30

			current_total = 0
			while current_total <= 100
				acthash.each do |x,y|
					acthash[x] = (y+current_total) 
					current_total = acthash[x]
					if current_total >= 100; break; end
				end
			end
			acthash['mov'] -= 100

			@@acthash = acthash

			# grab a random key based on the size of its number
			# greater number should mean a higher chance of occurance.
			# this should be noticable sense mov/lea should occure much more often



		end

		# ---------------------------------------------------------------------------

		def clear(reg1, reg2, reg3, extra)
			return choose_clearance(reg1, reg2, reg3, extra)
			#                                   Poly,  static option
		end


		def comp(reg1,reg2)
			return choose_compare(reg1, reg2)
		end
		## xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		def junkie
			# get lambda here to grab our automatic regs
			@@junk = ''; @@junkyard = []
			perms = Polymorph.instance_methods(false).length-4
			# -4 > top, init, junkie, to_s methods should not effect method count
			choice = $r.rand(0..perms)
			def rand_junk()
				# 1. don't use the reserved registers for junk >>>>
				def check_reg(junk_reg_ar)
					pass = true
					junk_reg_ar.each do |x|
						@@reserved.each do |y|
							if x == y; pass = false; end
						end
					end	
					return pass
				end
				pass = false
				until pass == true
					junk_reg_ar = []
					reg1 = $r.rand(0..$mr);   reg2 = $r.rand(0..$mr);   reg3 = $r.rand(0..$mr)
					junk_reg_ar.push(reg1);   junk_reg_ar.push(reg2);   junk_reg_ar.push(reg3)
					pass = check_reg(junk_reg_ar)
				end
				#puts reg1;puts reg2; puts reg3; puts '---------------'

				def prep_mov(reg1, reg2)
					tf = lambda{if $r.rand(0..1) == 1; return true; else; return false; end}
					if tf.call == true # rand true/false for data or register
						data = get_bytes(@reg_div)
						size = reg_size(data)
						if $ac != 'x64'
							while size == -1 # can't be a 64bit rand_data found by reg_size
								data = get_bytes(@reg_div)
								size = reg_size(data)
							end
						end
						if $ac != 'x64' and (reg1 == 4 or reg1 == 5 or reg1 == 6); size = 0; end
						@@junk = mov($reg[reg1][size], data)
					else
						if $ac != 'x64' and (reg1 == 4 or reg1 == 5 or reg1 == 6); size = 0; end
						@@junk = mov($reg[reg1][0], $reg[reg2][0])
						# tracker key's value for rax was overwritten by tracker key's value for rbx
					end
				end

				#!!!! data is always the same size as the register in [], so it would be [ax + 0x4142]
				# and never [ax + 0x41]
				# also, I need to combine more, so it could hold up to 3 registers and 1 num
				# all math is pre-calculated by the nasm compiler

				def prep_lea(reg1,reg2)
					def calc_lea(reg1,reg2)
						data = get_bytes(@reg_div)
						size = reg_size(data)
						def rand_data(data,size)
							# size will be randomized later

							if $ac == 'x64'
								while size == 0 or size == 3 or (size == 1 and data.to_i(16) >= 2147483647)
									# can't lea a qword
									data = get_bytes(@reg_div)
									size = reg_size(data)
								end
							elsif $ac == 'x86'
								while size == 2 or data.to_i(16) >= 2147483647
									# can't lea a qword
									data = get_bytes(@reg_div)
									size = reg_size(data)
									while size == -1
										data = get_bytes(@reg_div)
										size = reg_size(data)
									end
								end 
							end
							return data,size
						end

						rand_reg  = lambda {return $r.rand(0..$mr)}
						rand_size = lambda {if $ac == 'x64'; ms = 3; else ms = 2;end; return $r.rand(0..ms)}
						rand_op   = lambda {bit_mod = $r.rand(0..2); if bit_mod == 0; return ' - '; elsif bit_mod == 1; return ' * '; else return ' + '; end}

						data,size = rand_data(data,size)

						rand_op = rand_op.call
						if rand_op == ' * '
							tmp = $r.rand(0..2)
							if tmp == 0
								data = '2'
							elsif tmp == 1
								data = '4'
							else
								data = '8'
							end
						end

						tf = $r.rand(0..1)
						# !!! add a skew to what gets more, the [reg + data] or [data]
						if tf == 0
							if $ac == 'x64'
								data = $reg[rand_reg.call][rand_size.call] + rand_op + data
							else
								data = $reg[rand_reg.call][0] + rand_op + data
							end
							@@junk = lea($reg[reg1][size], data)
						elsif  tf == 1
							@@junk = lea($reg[reg1][size], data)
						end
					end
					calc_lea(reg1,reg2)
					if $nni == false
						while ((con(@@junk)).unpack("H*").join.scan(/../).index('00')) != nil
							calc_lea(reg1,reg2)
						end
					end
				end

				# random bitwise function start
				gc = $r.rand(0..100)
				# !!!! del > the following require reg tracking (this will come in later versions)
				while  gc.between?(@@acthash['mul'],@@acthash['div'])  \
					or gc.between?(@@acthash['dec'],@@acthash['push']) \
					or gc.between?(@@acthash['push'],@@acthash['pop'])
					gc = $r.rand(0..100)
				end

				case true
					when gc.between?(0               , @@acthash['mov']);  prep_mov(reg1,reg2)
					when gc.between?(@@acthash['mov'], @@acthash['lea']);  prep_lea(reg1,reg2)
					when gc.between?(@@acthash['lea'], @@acthash['inc']);  inc($reg[reg1][0])
					when gc.between?(@@acthash['inc'], @@acthash['dec']);  dec($reg[reg1][0])
					when gc.between?(@@acthash['dec'], @@acthash['push']); pushit($reg[reg1][0])
					when gc.between?(@@acthash['push'],@@acthash['pop']);  popit($reg[reg1][0])
					when gc.between?(@@acthash['pop'], @@acthash['add']);  add($reg[reg1][0],$reg[reg2][0])
					when gc.between?(@@acthash['add'], @@acthash['sub']);  subit($reg[reg1][0],$reg[reg2][0])
					when gc.between?(@@acthash['sub'], @@acthash['mul']);  mul($reg[reg1][0])
					when gc.between?(@@acthash['mul'], @@acthash['div']);  div($reg[reg1][0])
					when gc.between?(@@acthash['div'], @@acthash['xchg']); xchg($reg[reg1][0],$reg[reg2][0])
					when gc.between?(@@acthash['xchg'],@@acthash['xor']);  xor($reg[reg1][0],$reg[reg2][0])
					else
						puts 'no hit'
				end	

			end

			def splash_effect()
				def grab_random_bytes()
					def get_byte_array()
						gba = lambda {return ([$r.rand(0..255)].pack("V*").gsub /\000*$/,'').unpack("H*").join}
						junk_count = $r.rand(($sm*$mult).to_i..$sm).to_i
						count = 0
						junk_array = []
						until junk_count == count
							new_byte = gba.call
							if $badchars.index(new_byte) == nil
								junk_array.push(new_byte)
							end
							count += 1
						end
						return junk_array,junk_count
					end
					count = 0
					count_max = 8 # higher count means higher accuracy but longer loading time
					junk_array,junk_count = get_byte_array
					#while junk_count > 70 and junk_count < 135 # dead zone
					#	junk_count = $r.rand(($sm*$mult).to_i..$sm)
					#end
					until count > count_max
						count += 1
						if junk_array.uniq.length + $badchars.length != (junk_array + $badchars).uniq.length
							junk_array,junk_count = get_byte_array
							count = 0
						end
					end

					junk_ar_join = junk_array.join
					junk_ar_len = junk_array.length
					if junk_count < 128
						junk_dis = ([junk_ar_len].pack("V*").gsub /\000*$/,'').unpack("H*").join
					else
						junk_dis = ([junk_ar_len].pack("V*")).unpack("H*").join
					end
					return junk_array,junk_count,junk_ar_join,junk_ar_len,junk_dis
				end

				junk_ar,junk_count,junk_ar_join,junk_ar_len,junk_dis = grab_random_bytes()

				restart = true
				count = 0
				max_count = ($ric*2) # times 2 becuse here you are 2x as likely to fail.
				while restart == true and count < max_count
					restart = false
					if junk_count < 128
						## yes, this re-enforcement is necessary, ruby isn't always reliable
						if junk_dis.to_i(16) != junk_ar_len \
							or junk_dis.to_i(16) != junk_count \
							or junk_dis.to_i(16) != junk_ar_join.length/2 \
							or junk_ar_join.length/2 != junk_count \
							or [junk_dis + '000000'].pack("H*").unpack("V*").join.to_i != junk_ar_len \
							or [junk_dis + '000000'].pack("H*").unpack("V*").join.to_i != junk_count \
							or [junk_dis + '000000'].pack("H*").unpack("V*").join.to_i != junk_ar_join.length/2
							restart = true
						end
						jmp_junk = "eb"+junk_dis+junk_ar_join
					else
						## yes, this re-enforcement is necessary, ruby isn't always reliable
						if [junk_dis].pack("H*").unpack("V*").join.to_i != junk_ar_len or junk_ar_len != junk_count \
							or [junk_dis].pack("H*").unpack("V*").join.to_i != junk_count \
							or [junk_dis].pack("H*").unpack("V*").join.to_i != junk_ar_join.length/2 \
							or junk_dis.scan(/../).reverse.join.to_i(16) != [junk_dis].pack("H*").unpack("V*").join.to_i \
							or junk_dis.scan(/../).reverse.join.to_i(16) != junk_ar_len \
							or junk_dis.scan(/../).reverse.join.to_i(16) != junk_ar_join.length/2
							restart = true
						end
						jmp_junk = "e9"+junk_dis+junk_ar_join
					end

					if restart == true or ((junk_dis.scan(/../))+$badchars).uniq.length != ((junk_dis.scan(/../)).uniq).length + $badchars.uniq.length
						count = 0
						junk_ar,junk_count,junk_ar_join,junk_ar_len,junk_dis = grab_random_bytes()
					else
						count += 1
					end
				end

				return [jmp_junk].pack("H*")
			end

			def Scavenger()
				## rand_junk start
				# calc the amount of times you want to loop up junk
				@@junkyard = []
				splash_effect_ar = []

				if @@ss == false and $nni == true # max junk
					junkpit = $r.rand(($jo*$mult).to_i..$jo)
				elsif @@ss == false and $jo > 0 # no null max
					if $jo > 2; $jo = 2; end
					junkpit = $r.rand(1..$jo)
				else # single scrap
					junkpit = 1
				end

				## loop on that count to gather many scraps before using metasm to enhance speed
				## also gather the num of splash hits
				counter = 0
				while junkpit > counter
					if ($r.rand(0..100) < $r.rand(($sc*$mult).to_i..$sc) and $nni == true and @@ss == false and $sp != 'never') or $sp == 'always'
						splash_return = splash_effect()
						splash_effect_ar.push(splash_return)
					else
						rand_junk()
						@@junkyard.push(@@junk+"\n")
					end
					counter += 1
				end

				if    $nni == false and @@junkyard.length > 0  and junkpit > 0 and $sp != 'always'
					@@junkyard = con(@@junkyard.join)
					@@junk = con(@@junk) #!!! del needed for $off, make new class instance for $off (99,99,99)
				elsif $nni == true  and @@junkyard.length > 0  and junkpit > 0 and $sp != 'always'
					splash_count = splash_effect_ar	.length
					junkyard_size = @@junkyard.length
					splash_index = []

					if splash_count < junkyard_size and splash_count > 0
						# index the locations of where to inject splash into the junkyard
						count = 0
						while splash_count > count
							ti = $r.rand(1..junkyard_size)
							while splash_index.index(ti) != nil
								ti = $r.rand(1..junkyard_size)
							end
							splash_index.push(ti)
							count += 1
						end
						splash_index = splash_index.sort
						count = 0 # tracks current splash_index
						prev = 0  # holds prev splash_index
						junkyard_ar = []
						# make junkyard_ar a segmented str_bytecode version of @@junkyard

						while splash_count > count
							junkyard_ar.push(con(@@junkyard[prev..splash_index[count]].join))
							prev = splash_index[count].to_i+1
							count += 1
						end
		
						jmp_n_op = []
						count = 0
						until count == splash_count
							jmp_n_op.push(junkyard_ar[count] + splash_effect_ar[count])
							count += 1
						end
						@@junkyard = (jmp_n_op.join)
						@@junk = jmp_n_op[0] # junk is always the first array in junkyard

					else # no splash
						if @@junkyard.length == 1 # if junkyard = only 1 don't con @@junk
							@@junkyard = con(@@junkyard.join)
							@@junk = @@junkyard
						else
							@@junkyard = con(@@junkyard.join)
							@@junk = con(@@junk)
						end
					end
				elsif  $sp == 'always'
					@@junkyard = splash_effect_ar.join
				end
			end # Scavenger()

			Scavenger()
			if @@junk.length > 0 or salvage.length > 0
				count = 0
				count_max = 8 # higher count means higher accuracy but longer loading time
				retry_count = 0
				max_retries = 8
				while ((salvage.unpack("H*").join.scan(/../))+$badchars).uniq.length != ((salvage.unpack("H*").join.scan(/../)).uniq).length + $badchars.length
					retry_count += 1
					if retry_count > max_retries
						((salvage.unpack("H*").join.scan(/../))+$badchars).each do |x|
							($badchars).each do |y|
								if x == y
									if $silent
										true == true
									else
										puts "I am unable to remove the badchar: #{x} on ASM step #{@current_step}"
										quit()
									end
								end
							end
						end
					end
					Scavenger()
				end
			end
		end


		# Allow a DeXOR instance to grab a Polymorph instance's vars
		def junk       ; return @@junk       ; end
		def ss         ; return @@ss         ; end
		def looper     ; return @@looper     ; end
		def key        ; return @@key        ; end
		def code       ; return @@code       ; end
		def reserved   ; return @@reserved   ; end
		def stack_hold ; return @@stack_hold ; end
		def stack_count; return @@stack_count; end

		def salvage
			if @@junkyard.class == Array
				@@junkyard = @@junkyard.join
			end
			return @@junkyard 
		end

		# Allow the DeXOR instance modify the Polymorph's class
		def update_ss(x)         ; @@ss           = x; end
		def update_looper(x)     ; @@looper       = x; end
		def update_key(x)        ; @@key          = x; end
		def update_code(x)       ; @@code         = x; end
		def update_reserved(x)   ; @@reserved     = x; end
		def update_stack_hold(x) ; @@stack_hold   = x; end
		def update_stack_count(x); @@stack_count += x; end


		def to_s
			"#{hex(@@junk)}"
		end

	end # Polymorph
	# ---------------------------------------------------------------------------
end

rescue => e 
	puts e
	puts e.backtrace
end