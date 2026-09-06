// R2.4.6: dump the index order `Ordering.RANDOMIZED` yields for an interval,
// so lib/rng's +subset-indices can be compared against the pinned JVM.
// Usage: EnumDump <seed> <lo> <hi>  ->  the elements of lo..hi in the order
// EnumerableValue.SubsetEnumerator produces them.
import tlc2.value.RandomEnumerableValues;
import tlc2.value.impl.Enumerable;
import tlc2.value.impl.IntervalValue;
import tlc2.value.impl.Value;
import tlc2.value.impl.ValueEnumeration;

public class EnumDump {
    public static void main(String[] args) {
        long seed = Long.parseLong(args[0]);
        int lo = Integer.parseInt(args[1]);
        int hi = Integer.parseInt(args[2]);
        RandomEnumerableValues.setSeed(seed);
        IntervalValue iv = new IntervalValue(lo, hi);
        ValueEnumeration e = iv.elements(Enumerable.Ordering.RANDOMIZED);
        StringBuilder sb = new StringBuilder();
        Value v;
        while ((v = e.nextElement()) != null) {
            if (sb.length() > 0) sb.append(' ');
            sb.append(v.toString());
        }
        System.out.println(sb);
    }
}
