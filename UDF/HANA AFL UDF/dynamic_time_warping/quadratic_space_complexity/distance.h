#include<cmath>
#include<string>
#include<algorithm>
#include<exception>
#include<iostream>
using namespace std;

class DistanceFunction {
        public:
                virtual double calDistance(double num1, double num2)=0;

};


class EuclideanDistance : public DistanceFunction {
        virtual double calDistance(double num1, double num2){
                return sqrt(pow((num1 - num2),2));
        }
};

class BinaryDistance : public DistanceFunction{
        virtual double calDistance(double num1, double num2){
                if( num1 == num2) return 0;
                else return 1;
        }
};

class DistanceFactory{
        public:
        static DistanceFunction* EuclideanDistance_FN ;
        static DistanceFunction* BinaryDistance_FN;

        static DistanceFunction* getDistFunctionbyName(string distName){
                transform(distName.begin(),distName.end(),distName.begin(),::tolower);
                if( distName == "euclidean") return EuclideanDistance_FN;
                else if ( distName == "binary") return BinaryDistance_FN;
                else throw "Invalid Distance Name!";
        }
};

DistanceFunction* DistanceFactory :: EuclideanDistance_FN = new EuclideanDistance();
DistanceFunction* DistanceFactory :: BinaryDistance_FN = new BinaryDistance();

