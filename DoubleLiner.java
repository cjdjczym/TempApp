import java.util.ArrayList;
import java.util.List;

public class DoubleLiner {

    public static List<List<Float>> doubleLiner(List<List<Float>> src) {

        int srcRows = 24;
        int srcCols = 32;
        int dstRows = 24 * 4;
        int dstCols = 32 * 4;
        float scale_y = 0.25f;
        float scale_x = 0.25f;

        List<Float> temp = new ArrayList<>(dstCols);
        List<List<Float>> dst = new ArrayList<>();
        for (int i = 0; i < dstRows; i++) {
            dst.add(temp);
        }

        for (int j = 0; j < dstRows; j++) {
            float fy = (float) ((j + 0.5) * scale_y - 0.5);
            int sy = (int) fy;
            fy -= sy;
            sy = Math.min(sy, srcRows - 2);
            sy = Math.max(0, sy);

            float[] cbufy = new float[2];
            cbufy[0] = boundaryCtrl(1.f - fy);
            cbufy[1] = 1 - cbufy[0];

            for (int i = 0; i < dstCols; i++) {
                float fx = (float) ((i + 0.5) * scale_x - 0.5);
                int sx = (int) fx;
                fx -= sx;

                if (sx < 0) {
                    fx = 0;
                    sx = 0;
                }
                if (sx >= srcCols - 1) {
                    fx = 0;
                    sx = srcCols - 2;
                }

                float[] cbufx = new float[2];
                cbufx[0] = boundaryCtrl(1.f - fx);
                cbufx[1] = 1 - cbufx[0];

                dst.get(j).add(i, (src.get(sy).get(sx) * cbufx[0] * cbufy[0] +
                        src.get(sy + 1).get(sx) * cbufx[0] * cbufy[1] +
                        src.get(sy).get(sx + 1) * cbufx[1] * cbufy[0] +
                        src.get(sy + 1).get(sx + 1) * cbufx[1] * cbufy[1]));
            }

        }
        return dst;
    }

    public static float boundaryCtrl(float floatToInt) {
        if (floatToInt > 1)
            return 1;
        else if (floatToInt < 0)
            return 0;
        else return floatToInt;
    }

    public static void main(String[] args) {
        List<Float> test1 = new ArrayList<>();
        for (int i = 0; i < 32; i++) {
            test1.add(35.67f);
        }
        List<List<Float>> rsc = new ArrayList<>();
        for (int i = 0; i < 24; i++) {
            rsc.add(test1);
        }

        List<List<Float>> dst = doubleLiner(rsc);
        for (int i = 0; i < 24*4; i++) {
            System.out.println(dst.get(i));
        }
    }

}
