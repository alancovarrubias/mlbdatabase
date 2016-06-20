module Create
  class AirDensity

    @@c_array = [-0.30994571E-19, 0.11112018E-16, -0.17892321E-14, 0.21874425E-12, -0.29883885E-10,
      0.43884187E-8, -0.61117958E-6, 0.78736169E-4, -0.90826951E-2, 0.99999683]

    def run(baro, temp, dew)
      temp = fahr_to_cels(BigDecimal.new(temp, 4))
      dew = fahr_to_cels(BigDecimal.new(dew, 4))
      baro = BigDecimal.new(baro, 6)
      wv_p = eso(dew)
      da_p = baro - wv_p
      (rho(da_p, wv_p, temp) * 100).round(4)
    end


    private

      def fahr_to_cels(fahr)
        (fahr-32.0) * 5.0 / 9.0
      end


      def eso(temp)
        p = find_p(temp)
        p = p**8
        6.1078/p
      end

      def find_p(dew)
        @@c_array.inject {|memo, c| memo * dew + c }
      end

      def rho(da_p, wv_p, temp)
        kelvin = temp + 273.15
        (da_p / (287.0531 * kelvin)) + (wv_p / (461.4964 * kelvin))
      end


  end
end