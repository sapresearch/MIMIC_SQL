
import java.util.*;
import java.sql.*;
import java.lang.*;


public class add_seconds {
        public static void main(String[] args){
                 Timestamp time= Timestamp.valueOf("3446-09-13 18:08:38.142");
                 double add_time=Double.parseDouble("13.632");
               	 int sec = (int)(add_time);
		 int millisec = (int)(Math.ceil((add_time-sec)*1000));
		 System.out.println(add_time-sec);
		 System.out.println(add_time);
		 System.out.println(sec);
	         System.out.println(millisec);
		
		 Calendar cal = Calendar.getInstance();
                 cal.setTimeInMillis(time.getTime());
		 cal.add(Calendar.MILLISECOND, millisec);
                 cal.add(Calendar.SECOND, sec);
                 Timestamp later = new Timestamp(cal.getTime().getTime());
                 System.out.println(later);
		 System.out.println(time);

        }

}

