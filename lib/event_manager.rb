require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'



def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone_number)
    # Remove all non-numeric characters from the phone number
    phone_number = phone_number.gsub(/\D/, '')

    # If the phone number is less than 10 digits, it is a bad number
    return nil if phone_number.length < 10

    # If the phone number is 10 digits, assume it is good
    return phone_number if phone_number.length == 10

    # If the phone number is 11 digits and the first digit is 1, trim the 1
    # and use the remaining digits
    return phone_number[1..-1] if phone_number.length == 11 && phone_number[0] == '1'

    # Otherwise, the phone number is invalid
    return nil
end


def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyBY0x5D0w0AxavUH2DrZ4oKslu0ZsVGPgg'
    
    
    begin
        legislators = civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials 
    rescue
        'You can find your representative by visiting www.comoncause.com/'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv', 
    headers:true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    
    num_fixed = clean_phone_number(row[:homephone])
    legislators = legislators_by_zipcode(zipcode)
    form_letter = erb_template.result(binding)
    
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id,form_letter)
end