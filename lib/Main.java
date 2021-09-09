import java.util.ArrayList;
import java.util.List;


public class Main {
    //原始尺寸
    public static int x1=32;
    public static int y1=24;
    //目标尺寸
    public static int x2=512;
    public static int y2=384;
    //k=x2/x1=y2/y1
    public static int k=16;

    public static void main(String[] args) {
        //list为造的数据 [0,1,2,...]
        List <Double> list= new ArrayList<Double>();
        for(int i=0;i<x1*y1;++i){
            list.add((double)i);
        }

        List <List<Double>> ans= refactor2(list);

    }
    //插值
    public static List <List<Double>> refactor2(List <Double> data){
        List <List<Double>> ans = new ArrayList <List<Double>>();
        for(int i=0;i<x2;++i){
            ans.add(new ArrayList<Double>());
        }

        for(int i=0;i<x2;++i){
            for (int j=0;j<y2;++j){
                ans.get(i).add(data.get((i/k)*y1+(j/k)));
            }
        }
        //下为调试用输出

//        for(int i=0;i<x2;++i){
//            for (int j=0;j<y2;++j){
//                System.out.print(ans.get(i).get(j)+" ");
//            }
//            System.out.println("");
//        }
        return ans;
    }

}
