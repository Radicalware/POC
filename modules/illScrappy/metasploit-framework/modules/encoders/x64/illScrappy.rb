#!/usr/bin/env ruby

$dgb = false
$t = '---test---'
## scrappy.rb is a Radicalware product programed by Scourge
## github.com/Radicalware
## Scrappy.rb is under the APACHE v2 Licence

###
## This module requires Metasploit: https://metasploit.com/download
## Current source: https://github.com/rapid7/metasploit-framework
###


require 'metasm'                                        # programmed by Rapid7
require File.join(File.dirname(__FILE__),'..','r3Evolve.rb') # programmed by Scourge
require File.join(File.dirname(__FILE__),'..','salvage.rb')  # programmed by Scourge
## make sure that your r3Evolve.rb and salvage.rb are both in the same dir as Scrappy.rb

class MetasploitModule < Msf::Encoder::XorAdditiveFeedback

	def initialize
		super(
		'Name'             => 'ill Scrappy/r3Evolve v1.0.0/v1.0.0 Trojan Encoder [arg "help" for help]',
		'Description'      => 'use arg "help" to display helping info',
		'Author'           => [ 'Joel Leagues' ],
		'Arch'             => ARCH_X64,
		'License'          => 'APACHE v2',
		'Decoder'          =>
			{
				'KeySize'      => 8,
				'KeyPack'      => 'Q',
				'BlockSize'    => 8,
			}
		)
	@retries=0
	end

	def can_preserve_registers?
		false
	end
	# https://ruby-doc.org/core-2.3.0/String.html#method-i-unpack

	def decoder_stub( state, opts={} )
begin
	
		ill_scrappy = Salvage::Start.new(state,datastore,arch)
		def savage_scavenger(ill_scrappy,state,datastore,arch)
			restart = true
			retry_count = 0
			while restart == true
				restart = false
				## This will fail if a bad byte is non-removable with the registers assigned
				begin
					ill_scrappy = Salvage::Start.new(state,datastore,arch)
					decoder, new_buffer = ill_scrappy.rabid_byte
				rescue => e
					decoder, new_buffer = ill_scrappy.rabid_byte
					restart = true
					retry_count += 1
				end
				if retry_count == 8
					puts "Failed to remove the bad-bytes given"
					exit
				end
			end
			return decoder, new_buffer
		end
		decoder, new_buffer = savage_scavenger(ill_scrappy,state,datastore,arch)
		## I need to check for bad bytes here one last time becaues the alignment of the 4
		## jmps may contain bad bytes. Under which case we will need to restart.
		## If you are using this for malware, don't specify bad bytes for best results. 
		
		restart = true
		badchars = (state.badchars).unpack("H*").join.scan(/../).uniq
		while badchars.length > 0 and restart == true
			restart = false
			decoder_ar = (decoder).unpack("H*").join.scan(/../).uniq
			badchars.each do |x|
				decoder_ar.each do |y|
					if x == y
						@retries += 1
						decoder, new_buffer = savage_scavenger(ill_scrappy,state,datastore,arch)
						if (/[0-9]/.match((datastore.to_s).index('SL').to_s)).to_s != ''
							true == true
						else
							puts "Bad Char Retry Count = #{@retries}"
						end
						restart = true
						break
					end
				end
			end
		end

		#total =  (decoder).unpack("H*").join.scan(/../).join(' ')
		#File.open('tmp',"w"){|f| f.write("\ntotal ---------------------\n"+total+"\n")}

		state.buf = new_buffer
		return decoder
		## the state.decoder_key_offset is not needed sense we used the $xork directly
rescue => e
	puts e
	puts e.backtrace	
end # begin/rescue


	end # decoder_stub
end # MetasploitModule

=begin 
Paste the following into irb to have fun with metasm
Same effect as "Rmutate -s <content> -raw -<linux/win/osx> -wr

require 'metasm'
def con(optc)
Metasm::Shellcode.assemble(Metasm::X64.new, optc).encode_string.unpack("H*").join
end

def con3(optc)
Metasm::Shellcode.assemble(Metasm::Ia32.new, optc).encode_string.unpack("H*").join
end

=end