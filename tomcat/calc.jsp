<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="java.lang.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="java.util.regex.*"%>
<%@ page import="java.math.BigDecimal"%>

<%!
	String calc = "";
	static boolean divideByZero = false;
	static boolean operatorError = false;
	static boolean pushEqualButton = false;

	public static BigDecimal eval(String calc) {
		final char operator[] = { '+', '-', '*', '/' };
		ArrayList<BigDecimal> num = new ArrayList<BigDecimal>();
		ArrayList<Character> op = new ArrayList<Character>();

		int index = 0;
		for (int i = 0; i < calc.length(); i++) {
			for (int j = 0; j < operator.length; j++) {
				if (calc.charAt(i) == operator[j]) {
					num.add(new BigDecimal(calc.substring(index, i)));
					index = i + 1;
					op.add(operator[j]);
				}
			}
		}
		num.add(new BigDecimal(calc.substring(index, calc.length())));

		//debug
		//System.out.println(num);
		//System.out.println(op);

		BigDecimal ans = num.get(0);
		for (int i = 0; i < op.size(); i++) {
			Character temp = op.get(i);
			switch (temp) {
			case '+':
				ans = ans.add(num.get(i + 1));
				break;
			case '-':
				ans = ans.subtract(num.get(i + 1));
				break;
			case '*':
				ans = ans.multiply(num.get(i + 1));
				break;
			case '/':
				if (num.get(i + 1).compareTo(new BigDecimal("0")) != 0) {
					//割り切れたとき
					if(ans.remainder(num.get(i+1)).compareTo(new BigDecimal("0")) == 0){
						ans = ans.divide(num.get(i + 1));
					}else{
						ans = ans.divide(num.get(i + 1),5,BigDecimal.ROUND_HALF_UP);
					}
				} else {
					//0除算
					divideByZero = true;
					ans = new BigDecimal("0");
				}
				break;
			}
		}

		System.out.println(ans);

		return ans;

	}

	%>

<%!
public static String makeTable(ResultSet rs){
	String table = "<table><table border=\"1\" width=\"300\"><tr><th>ID</th><th>計算式</th></tr>";
	ArrayList<String> id = new ArrayList<String>();
	ArrayList<String> formula = new ArrayList<String>();
	try{
		while (rs.next()) {
            id.add(rs.getString("id"));
            formula.add(rs.getString("formula"));
    	}
	}catch(Exception e){
		System.out.println("error");
	}

	int len = id.size();

	for(int i = (len > 20 ? len - 20: 0);i < len; i++){
		table += "<tr><td>" + id.get(i) +"</td><td>"+formula.get(i)+"</td></tr>";
	}

	table += "</table>";

	return table;
}
%>


<%!
public static boolean needToAddDB(String calc){
	final String op = "+-*/";
	final Pattern p = Pattern.compile("[0-9]");
	Matcher m = p.matcher(calc);

	for(int i = 0; i < op.length(); i++){
		int num = calc.indexOf(op.charAt(i));
		if(num != -1){
			return true && m.find();
		}
	}
	return false;
}
%>



<%!
public static boolean isVaildCalc(String calc){
	boolean operatorNum = false,dotNum = false;
	final String op = "+-*/";


	char front = calc.charAt(0);
	char back = calc.charAt(calc.length()-1);
	if(front == '/' || front == '*' || op.indexOf(back) != -1){
		return false;
	}





	for(int i = 0; i < calc.length(); i++){
		char temp = calc.charAt(i);
		if(temp == '+' || temp == '-' || temp == '*' || temp == '/'){
			dotNum = false;
		}else if(temp == '.' && dotNum == false){
			dotNum = true;
		}else if(temp == '.' && dotNum == true){
			return false;
		}
	}
	return true;
}
%>

<%


//MySQLの場合、URLの形式は次のようになります。jdbc:mysql://(サーバ名):(ポート番号)/(データベース名)
//refer this https://qiita.com/norikiyo777/items/0bc3bf28b94ae4922b9a

    // 変数の準備
    Connection con = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    String sql = "SELECT * FROM calcHistory";
    String databasename = "calcdata";
    String querystring = "?UTF-8&serverTimezone=JST";
    String url = "jdbc:mysql://mysql:3306/" + databasename;   //dockerで動かすときは，localhostをmysqlのコンテナ名に変える
    String user = "root";
    String password = "password";
    String table = "";

    // load JDBC driver
    Class.forName("com.mysql.jdbc.Driver").newInstance(); // tomcatのバージョンが古いとここで例外発生 tomcat9(java11)で動作ok
    // connect to database
    con = DriverManager.getConnection(url, user, password);
    stmt = con.prepareStatement(sql);
    // 実行結果取得
    rs = stmt.executeQuery();
    table = makeTable(rs);

    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
    String w = request.getParameter("w");
    String msg = "";
    String query = request.getParameter("query");
    String id = request.getParameter("id");
    final String operator = "+-*/";

    if (w != null && !w.equals("")) {
      pushEqualButton = false;
      if (w.equals("AC")) {
        System.out.println("AC");
        calc = "";
        msg = "式をクリアしました。";
      } else if (w.equals("=")) {
    	pushEqualButton = true;
        if (!calc.equals("")) {
          if(needToAddDB(calc) && isVaildCalc(calc)){
	          String insertSql = "INSERT INTO calcHistory (formula) values ('" + calc + "')";
	          int num = stmt.executeUpdate(insertSql);
	          rs = stmt.executeQuery();
	          table = makeTable(rs);
          }
          char front = calc.charAt(0);
          char back = calc.charAt(calc.length() - 1);

          //先頭が符号のとき
          if (front == '+' || front == '-' ) {
            StringBuilder calctemp = new StringBuilder(calc);
            calctemp.insert(0, "0");
            calc = calctemp.toString();
          }

          if (isVaildCalc(calc)) {
            calc = String.valueOf(eval(calc));
          } else {
            System.out.println("operator error");
            operatorError = true;
          }

        } else {
          msg = "式が入力されていません";
        }
      } else if (w.equals("back")) {
        System.out.println("back");
        System.out.println(calc.length());
        calc = calc.substring(0, calc.length() - 1 > 0 ? calc.length() - 1 : 0);

      } else if (w.equals(".")){
    	  System.out.println("小数点が押されました");
    	  //System.out.println(calc.charAt(calc.length()-1));
    	  if((!calc.equals("")) && (calc.charAt(calc.length()-1) != '.')){
    		  System.out.println(calc);
    		  System.out.println("小数点を追加します");
    		  //System.out.println(w);
    		  calc += w;
    		  System.out.println(calc);
    	  }else{
    		  System.out.println("この状況で小数点は押せません");
    	  }

      } else {
        System.out.println("数字または+-*/が押されました．");

        if (calc.length() != 0) {
          boolean flag1 = !Character.isDigit(calc.charAt(calc.length() - 1));
          boolean flag2 = !Character.isDigit(w.charAt(0));

          //System.out.println(flag1 + " " + flag2);

          if (flag1 && flag2) {
            calc = calc.substring(0, calc.length() - 1) + w;
          } else {
            calc += w;
          }
        } else {
          calc += w;
        }
      }
    }

    if (calc != null && !calc.equals("")) {
    	//System.out.println("check");
      if (divideByZero) {
        msg = "0除算が発生しました。ACを押してやり直してください。";
        divideByZero = false;
      } else if (operatorError) {
        msg = "不正な式が入力されました。ACを押してやり直してください。";
        operatorError = false;
      } else if (calc.charAt(calc.length() - 1) == '.' ){
    	 msg = "<hr>入力された計算式は" + calc + "です<hr>";
      } else {
        try {
          // もし答えが3.0になったら3と表示したい
          BigDecimal c = new BigDecimal(calc);
        } catch (Exception e) {
          // calcの中身が計算式のときなにもしない
          System.out.println("cccc");
        }
        msg = (pushEqualButton ? "<hr>計算結果は":"<hr>入力された計算式は") + calc + "です<hr>";
      }
    }

    //ここからはSQL関連
    //System.out.println("queryにはいっている文字列は"+query);

    if(query != null){
	    if(query.equals("reset")){
	    	String resetSQL = "TRUNCATE TABLE calcHistory";
	    	int num = stmt.executeUpdate(resetSQL);
	    	table = makeTable(rs);
	    }else if(query.equals("return")){
	    	int index = 0;
	    	try{
	    		index = Integer.parseInt(id);
	    	}catch(Exception e){
	    		System.out.println("入力されたidがintではありません．");
	    	}
	    	System.out.println("indexの値は"+index);

	    	String getSQL = "SELECT formula from calcHistory WHERE id='" + index + "'";
	    	System.out.println(getSQL);
	    	ResultSet temp = stmt.executeQuery(getSQL);

	    	try{
		    	temp.next();
		    	calc = temp.getString("formula");
		    	msg = "<hr>入力された計算式は" + calc + "です<hr>";
	    	}catch(Exception e){
	    		msg = "idが違うか，idが入力されていません ACを押してやり直してください";
	    	}
	    }
    }




%>

<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>電卓</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="normalize.css" />
    <link rel="stylesheet" href="style.css" />
  </head>
  <body>
    <div class="container">
      <div class="text">
        <h1>電卓</h1>
        <p class="explain">説明：式は前から評価されます。(例:1+2*3=7ではなく 1+2*3=9と評価される)</p>

        <!-- <p>ここに計算式が入る</p> -->
        <!-- <p>ここには計算結果が入る</p> -->
        <%=msg %>
      </div>

      <div class="main-aside-flex">
        <main class="main">
          <form action="calc.jsp" method="post" class="calc-button">
            <div class="button-area">
              <div class="num-wrapper">
                <input name="w" type="submit" class="num" value="7" />
                <input name="w" type="submit" class="num" value="8" />
                <input name="w" type="submit" class="num" value="9" />
                <br>
                <input name="w" type="submit" class="num" value="4" />
                <input name="w" type="submit" class="num" value="5" />
                <input name="w" type="submit" class="num" value="6" />
                <br>
                <input name="w" type="submit" class="num" value="1" />
                <input name="w" type="submit" class="num" value="2" />
                <input name="w" type="submit" class="num" value="3" />
                <br>
                <input name="w" type="submit" class="num" value="0" />
                <input name="w" type="submit" class="num" value="." />
              </div>
              <div class="operator-wrapper">
                <input name="w" type="submit" class="num" value="AC" />
                <input name="w" type="submit" class="num" value="+" />
                <input name="w" type="submit" class="num" value="-" />
                <input name="w" type="submit" class="num" value="*" />
                <input name="w" type="submit" class="num" value="/" />
                <input name="w" type="submit" class="num" value="=" />
                <input name="w" type="submit" class="num" value="back" />
              </div>
            </div>
          </form>
        </main>
        <aside class="aside">
          <h1>計算履歴(最新20件)</h1>
          <%=table %>

          <form action="calc.jsp" class="historyForm" method="post">
            <p>ID：<input type="text" name="id" size="10" /></p>

            <input type="submit" value="return" name="query" />
            <input type="submit" class = "resetbutton" value = "reset" name="query" onclick="func1();" />
          </form>
        </aside>
      </div>
    </div>
    <script>
      "use strict";
      let func1 = function () {
       	let ele = document.querySelector(".resetbutton")
        console.log(ele);
        if(window.confirm("本当にテーブルをリセットしますか")){
          alert("テーブルをリセットしました");
          ele.setAttribute("name","query");
        }else{
          // alert("なにもしません");
          ele.setAttribute("name","noquery");
        }
      };
    </script>
  </body>
</html>


