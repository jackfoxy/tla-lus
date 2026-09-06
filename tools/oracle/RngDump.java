// RngDump — dump tlc2.util.RandomGenerator draws for a seed list (unit 9.1).
// Ground truth for the Hoon lib/rng java.util.Random port. For each seed
// (decimal long arg) prints, from a fresh setSeed, ten nextInt (unsigned
// 32-bit hex), ten nextLong (unsigned 64-bit hex), ten nextDouble
// (doubleToRawLongBits hex), ten nextPrime (decimal), and the nextLong after
// setSeed(seed, 4). Consumed by tools/gen-rng-tests.py.
import tlc2.util.RandomGenerator;

public class RngDump {
  public static void main(String[] args) {
    for (String arg : args) {
      long s = Long.parseLong(arg);
      RandomGenerator r = new RandomGenerator();
      System.out.printf("SEED %x%n", s);
      r.setSeed(s);
      StringBuilder b = new StringBuilder("INT");
      for (int i = 0; i < 10; i++) b.append(" ").append(Integer.toHexString(r.nextInt()));
      System.out.println(b);
      r.setSeed(s);
      b = new StringBuilder("LONG");
      for (int i = 0; i < 10; i++) b.append(" ").append(Long.toHexString(r.nextLong()));
      System.out.println(b);
      r.setSeed(s);
      b = new StringBuilder("DBL");
      for (int i = 0; i < 10; i++)
        b.append(" ").append(Long.toHexString(Double.doubleToRawLongBits(r.nextDouble())));
      System.out.println(b);
      r.setSeed(s);
      b = new StringBuilder("PRIME");
      for (int i = 0; i < 10; i++) b.append(" ").append(r.nextPrime());
      System.out.println(b);
      r.setSeed(s, 4);
      System.out.printf("SEEDCNT4 %x%n", r.nextLong());
    }
  }
}
