#!/usr/bin/env ruby

# file: polyrex_calendarbase.rb

require 'polyrex'
require 'date'
require 'nokogiri'
require 'chronic_duration'
require 'chronic_cron'
require 'rxfhelper'


module LIBRARY

  def fetch_filepath(filename)

    lib = File.dirname(__FILE__)
    File.join(lib, filename)
  end
  
  def fetch_file(filename)

    filepath = fetch_filepath filename
    read filepath
  end
  

  def generate_webpage(xml, xsl)
    
    # transform the xml to html
    doc = Nokogiri::XML(xml)
    xslt  = Nokogiri::XSLT(xsl)
    xslt.transform(doc).to_s   
  end

  def read(s)
    RXFHelper.read(s).first
  end
end

h = {
  calendar: 'calendar[year]',
     month: 'month[n, title]',
      week: 'week[n, mon, no, label]',
       day: 'day[sdate, xday, event, bankholiday, title, sunrise, sunset]',
     entry: 'entry[time_start, time_end, duration, title]'
}

visual_schema = h.values.join '/'

class CalendarObjects < PolyrexObjects
end

CalendarObjects.new(visual_schema)

class CalendarObjects::Month < PolyrexObjects::Month
  
  def initialize(filename)
    
    @filename = filename
    
    buffer = File.read filename
    @doc = Rexle.new buffer    
    @node = @doc.root
    
  end
    
  def save(filename=@filename)    
    File.write filename, @doc.xml(pretty: true)
  end
  
  def to_xml(options={})
    @doc.xml(options)
  end
end





class Calendar < Polyrex
  include LIBRARY

  attr_accessor :xslt, :css_layout, :css_style, :filename
  
  alias months records

  def inspect()
    "#<Calendar:%s" % __id__
  end
  
  def month(n)
    self.records[n-1]
  end

  def to_webpage()

    year_xsl        = read(self.xslt)
    year_layout_css = fetch_file self.css_layout
    year_css        = fetch_file self.css_style
    File.open('self.xml','w'){|f| f.write (self.to_xml pretty: true)}
    File.open(File.basename(self.xslt),'w'){|f| f.write year_xsl }
    #html = Rexslt.new(month_xsl, self.to_xml).to_xml

    html = generate_webpage self.to_xml, year_xsl
    {self.filename => html, 
      self.css_layout => year_layout_css, self.css_style => year_css}

  end           
end

class PolyrexObjects
  
    class Month
      include LIBRARY

      attr_accessor :xslt, :css_layout, :css_style

      def inspect()
        "#<CalendarObjects::Month:%s" % __id__
      end            
      
      def d(n)
        self.records[n-1]
      end
        
      def find_today()
        sdate = Time.now.strftime("%Y-%b-%d")
        self.element "//day/summary[sdate='#{sdate}']"      
      end
      
      def highlight_today()

        # remove the old highlight if any
        prev_day = self.at_css '.today'
        prev_day.attributes.delete :class if prev_day
        
        today = find_today()
        today.attributes[:class] = 'today'
        
      end      
      
    end
    
    class Week
      include LIBRARY

      def inspect()
        "#<CalendarObjects::Week:%s" % __id__
      end
      
    end  
    
    class Day
          
      def date()
        Date.parse(self.sdate)
      end

      def wday()
        self.date.wday
      end   

      def day()
        self.date.day
      end
      
    end

end



class PolyrexCalendarBase
  include LIBRARY


  attr_accessor :xsl, :css, :calendar, :month_xsl, :month_css
  attr_reader :day
  
  def initialize(calendar_file=nil, year: Date.today.year.to_s)

    @calendar_file = calendar_file

    @year = year.to_s

    h = {
      calendar: 'calendar[year]',
         month: 'month[n, title]',
          week: 'week[n]',
           day: 'day[sdate, xday, event, bankholiday, title, sunrise, sunset]',
         entry: 'entry[time_start, time_end, duration, title]'
    }
    @schema = %i(calendar month day entry).map{|x| h[x]}.join '/'
    @visual_schema = h.values.join '/'


    if calendar_file then
      @calendar = Calendar.new calendar_file
      @id = @calendar.id_counter

    else
      @id = '1'
      # generate the calendar

      a = (Date.parse(@year + '-01-01')...Date.parse(@year.succ + '-01-01')).to_a

      @calendar = Calendar.new(@schema, id_counter: @id)
      @calendar.summary.year = @year

      a.group_by(&:month).each do |month, days| 

        @calendar.create.month no: month.to_s, title: Date::MONTHNAMES[month]  do |create|
          days.each do |x|
            create.day sdate: x.strftime("%Y-%b-%d"), xday: x.day.to_s, title: Date::DAYNAMES[x.wday]
          end
        end
      end

    end

    visual_schema = h.values.join '/'
    CalendarObjects.new(visual_schema)
       
  end
  
  def find(s)
    dt = Chronic.parse s, now: Time.local(@year,1,1)
    @calendar.month(dt.month).d(dt.day)
  end
  
  def to_xml()
    @calendar.to_xml pretty: true
  end

  def import_events(objx)
    @id = @calendar.id_counter
    method('import_'.+(objx.class.to_s.downcase).to_sym).call(objx)
    self
  end
  
  alias import! import_events

  def inspect()
     %Q(=> #<PolyrexCalendarBase:#{self.object_id} @id="#{@id}", @year="#{@year}">)
  end  
  
  def month(n)
    @calendar.month(n)
  end
  
  def months
    @calendar.records
  end
  
  def parse_events(list)    
    
    polyrex = Polyrex.new('events/dayx[date, title]/entryx[start_time, end_time,' + \
      ' duration, title]')

    polyrex.format_masks[1] = '([!start_time] \([!duration]\) [!title]|' +  \
      '[!start_time]-[!end_time] [!title]|' + \
      '[!start_time] [!title])'

    polyrex.parse(list)

    self.import_events polyrex
    # for testing only
    #polyrex
  end

  def save(filename=@calendar_file)
    @calendar_file = 'calendar.xml' unless filename
    @calendar.save filename, pretty: true
  end
  
  def this_week()

    dt = DateTime.now
    days = @calendar.month(dt.month).day

    r = days.find {|day| day.date.cweek == dt.cweek }    
    pxweek = PolyrexObjects::Week.new
    pxweek.mon = Date::MONTHNAMES[dt.month]
    pxweek.no = dt.cweek.to_s
    pxweek.label = ''
    days[days.index(r),7].each{|day| pxweek.add day }

    pxweek
  end

  def this_month()
    @calendar.month(DateTime.now.month)
  end

  def import_bankholidays(dynarex)
    import_dynarex(dynarex, :bankholiday=)
  end

  def import_recurring_events(dynarex)

    title = dynarex.summary[:event_title]
    cc = ChronicCron.new dynarex.summary[:description].split(/,/,2).first
    time_start= "%s:%02d" % cc.to_time.to_a.values_at(2,1)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day
      record = {title: title, time_start: time_start}

      @calendar.month(m).d(d).create.entry record
    end
  end

  def import_sunrise_times(dynarex)
    import_suntimes dynarex, :sunrise=
  end

  def import_sunset_times(dynarex)
    import_suntimes dynarex, :sunset=
  end
  
  private

  def import_suntimes(dynarex, event_type=:sunrise=)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day
      @calendar.month(m).d(d).method(event_type).call event[:time]
    end
  end
  
  def import_dynarex(dynarex, daytype=:event=)

    dynarex.flat_records.each do |event|

      dt = DateTime.parse(event[:date])
      m, d = dt.month, dt.day

      case daytype
        
        when :event=
          
          if dynarex.fields.include?(:time) then

            match = event[:time].match(/(\S+)\s*(?:to|-)\s*(\S+)/) 

            if match then

              start_time, end_time = match.captures
              # add an event entry
              title = [event[:title], dynarex.summary[:label], 
                                event[:desc]].compact.join(': ')
              record = {
                title: title, 
                time_start: Time.parse(start_time).strftime("%H:%M%p"), 
                time_end: Time.parse(end_time).strftime("%H:%M%p")
              }

              @calendar.month(m).d(d).create.entry record
            else

              dt = DateTime.parse(event[:date] + ' ' + event[:time])
              # add the event
              title = [event[:title], dynarex.summary[:label], 
                                event[:desc]].compact.join(': ')
              event_label = "%s at %s" % [title, dt.strftime("%H:%M%p")]

              @calendar.month(m).d(d).method(daytype).call event_label
            end

          else

            event_label = "%s at %s" % [event[:title], dt.strftime("%H:%M%p")]
            @calendar.month(m).d(d).method(daytype).call event_label
          end

        else

          event_label = "%s" % event[:title]
          @calendar.month(m).d(d).method(daytype).call event_label
      end

    end
  end

  def import_polyrex(polyrex)

    polyrex.records.each do |day|

      dt = day.date

      sd = dt.strftime("%Y-%b-%d ")
      m, i = dt.month, dt.day
      cal_day = @calendar.month(m).d(i)

      cal_day.event = day.title

      if day.records.length > 0 then

        raw_entries = day.records

        entries = raw_entries.inject({}) do |r,entry|

          start_time = entry.start_time  

          if entry.end_time.length > 0 then

            end_time = entry.end_time
            duration = ChronicDuration.output(Time.parse(sd + end_time) \
              - Time.parse(sd + start_time))
          else

            if entry.duration.length > 0 then
              duration = entry.duration
            else
              duration = '10 mins'
            end

            end_time = (Time.parse(sd + start_time) + ChronicDuration.parse(duration))\
              .strftime("%H:%M")
          end

          r.merge!(start_time => {time_start: start_time, time_end: end_time, \
            duration: duration, title: entry.title})

        end

        seconds = entries.keys.map{|x| Time.parse(x) - Time.parse('08:00')}

        unless dt.saturday? or dt.sunday? then
          rows = slotted_sort(seconds).map do |x| 
            (Time.parse('08:00') + x.to_i).strftime("%H:%M") if x
          end
        else
          rows = entries.keys
        end

        rows.each do |row|
          create = cal_day.create
          create.id = @id
          create.entry entries[row] || {}
        end        

      end  
    end 
    
  end
    
  def slotted_sort(a)

    upper = 36000 # upper slot value
    slot_width = 9000 # 2.5 hours
    max_slots = 3  

    b = a.reverse.inject([]) do |r,x|

      upper ||= 10;  i ||= 0
      diff = upper - x

      if diff >= slot_width and (i + a.length) < max_slots then
        r << nil
        i += 1
        upper -= slot_width
        redo
      else
        upper -= slot_width if x <= upper
        r << x
      end
    end

    a = b.+([nil] * max_slots).take(max_slots).reverse
  end
  
end
