-- Module for calculating sunrise/sunset times for a given location
-- Based on algorithm by United Stated Naval Observatory, Washington
-- Link: https://edwilliams.org/sunrise_sunset_algorithm.htm
-- @author Alexander Yakushev
-- @author Alexander Pavlov (Zoviet)
-- @license CC0 http://creativecommons.org/about/cc0

local date = require("date")

local _M = {}

local cosH_rise,RA_rise,cosH_set,RA_set,sunrise,sunset,length

local current_time = nil
local srs_args
local rad = math.rad
local deg = math.deg
local floor = math.floor
local frac = function(n) return n - floor(n) end
local cos = function(d) return math.cos(rad(d)) end
local acos = function(d) return deg(math.acos(d)) end
local sin = function(d) return math.sin(rad(d)) end
local asin = function(d) return deg(math.asin(d)) end
local tan = function(d) return math.tan(rad(d)) end
local atan = function(d) return deg(math.atan(d)) end

local function days(utc)
	local UT = 0
	if utc then 
		UT = tonumber(string.match(utc, '%+(%d+)')) or 0
		utc = date(utc) 		
	else
		utc = date():toutc()
	end
	return utc:getyearday(), UT
end

local function fit_into_range(val, min, max)
   local range = max - min
   local count
   if val < min then
      count = floor((min - val) / range) + 1
      return val + count * range
   elseif val >= max then
      count = floor((val - max) / range) + 1
      return val - count * range
   else
      return val
   end
end

local function calc(t,lat,lon,zenith)
	local M = (0.9856 * t) - 3.289
	local L = fit_into_range(M + (1.916 * sin(M)) + (0.020 * sin(2 * M)) + 282.634, 0, 360)
	local RA = fit_into_range(atan(0.91764 * tan(L)), 0, 360) -- Прямое восхождение Солнца
	local Lquadrant  = floor(L / 90) * 90
	local RAquadrant = floor(RA / 90) * 90
	RA = RA + Lquadrant - RAquadrant
	RA = RA / 15
	local sinDec = 0.39782 * sin(L)
	local cosDec = cos(asin(sinDec))
	local cosH = (cos(zenith) - (sinDec * sin(lat))) / (cosDec * cos(lon))
	return cosH,RA
end

local function sun(utc,lat,lon,zenith)
	zenith = zenith or 90.5--90.83
	local days,UT = days(utc)	
	local lng_hour = lon/15
	local t_rise, t_set	
    local t_rise = days + ((6 - lng_hour) / 24)
    local t_set = days + ((18 - lng_hour) / 24)
    cosH_rise,RA_rise = calc(t_rise,lat,lon,zenith) -- часовой угол
	cosH_set,RA_set = calc(t_set,lat,lon,zenith)
	local H_rise,H_set,sunrise_i,sunset_i
	if cosH_rise > 1 then sunrise = nil 
	else
		H_rise = (360 - acos(cosH_rise))/15
		sunrise = H_rise + RA_rise - (0.06571 * t_rise) - 6.622	
		sunrise_i = fit_into_range(sunrise - lng_hour, 0, 24) + UT
		sunrise = date():sethours(0, 0, 0):addhours(sunrise_i):fmt('%Y-%m-%d %T')
	end
	if cosH_set < -1 then sunset = nil
	else
		H_set = acos(cosH_set)/15
		sunset = H_set + RA_set - (0.06571 * t_set) - 6.622	
		sunset_i = fit_into_range(sunset - lng_hour, 0, 24) + UT
		sunset = date():sethours(0, 0, 0):addhours(sunset_i):fmt('%Y-%m-%d %T')
	end
	if sunset and sunrise then length = sunset_i - sunrise_i end
end

--Sun's zenith for sunrise/sunset:

--	zenith:              
--  offical      = 90 degrees 50'
--  civil        = 96 degrees
-- nautical     = 102 degrees
-- astronomical = 108 degrees

function _M.get(utc,lat,lon,zenith)
	sun(utc,lat,lon,zenith)
	return sunrise, sunset,length
end

return _M
